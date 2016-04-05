//
//  Machine.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2015-12-05.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

///
/// State-machine which can `tryEvent()` (event-driven).
///
/// This is a superclass (simpler version) of `StateMachine` that doesn't allow `tryState()` (direct state change).
///
/// This class can be used as a safe state-container in similar way as [rackt/Redux](https://github.com/rackt/redux),
/// where `RouteMapping` can be interpretted as `Redux.Reducer`.
///
public class Machine<S: StateType, E: EventType>
{
    /// Closure argument for `Condition` & `Handler`.
    public typealias Context = (event: E?, fromState: S, toState: S, userInfo: Any?)

    /// Closure for validating transition.
    /// If condition returns `false`, transition will fail and associated handlers will not be invoked.
    public typealias Condition = Context -> Bool

    /// Transition callback invoked when state has been changed successfully.
    public typealias Handler = Context -> ()

    /// Closure-based route, mainly for `tryEvent()` (and also works for subclass's `tryState()`).
    /// - Returns: Preferred `toState`.
    public typealias RouteMapping = (event: E?, fromState: S, userInfo: Any?) -> S?

    internal typealias _RouteDict = [Transition<S> : [String : Condition?]]

    private lazy var _routes: [Event<E> : _RouteDict] = [:]
    private lazy var _routeMappings: [String : RouteMapping] = [:]

    /// `tryEvent()`-based handler collection.
    private lazy var _handlers: [Event<E> : [_HandlerInfo<S, E>]] = [:]

    internal lazy var _errorHandlers: [_HandlerInfo<S, E>] = []

    internal var _state: S

    //--------------------------------------------------
    // MARK: - Init
    //--------------------------------------------------

    public init(state: S, initClosure: (Machine -> ())? = nil)
    {
        self._state = state

        initClosure?(self)
    }

    public func configure(closure: Machine -> ())
    {
        closure(self)
    }

    public var state: S
    {
        return self._state
    }

    //--------------------------------------------------
    // MARK: - hasRoute
    //--------------------------------------------------

    /// Check for added routes & routeMappings.
    public func hasRoute(event event: E, transition: Transition<S>, userInfo: Any? = nil) -> Bool
    {
        guard let fromState = transition.fromState.rawValue,
            toState = transition.toState.rawValue else
        {
            assertionFailure("State = `.Any` is not supported for `hasRoute()` (always returns `false`)")
            return false
        }

        return self.hasRoute(event: event, fromState: fromState, toState: toState, userInfo: userInfo)
    }

    /// Check for added routes & routeMappings.
    public func hasRoute(event event: E, fromState: S, toState: S, userInfo: Any? = nil) -> Bool
    {
        return self._hasRoute(event: event, fromState: fromState, toState: toState, userInfo: userInfo)
    }

    internal func _hasRoute(event event: E?, fromState: S, toState: S, userInfo: Any? = nil) -> Bool
    {
        if self._hasRouteInDict(event: event, fromState: fromState, toState: toState, userInfo: userInfo) {
            return true
        }

        if self._hasRouteMappingInDict(event: event, fromState: fromState, toState: .Some(toState), userInfo: userInfo) != nil {
            return true
        }

        return false
    }

    /// Check for `_routes`.
    private func _hasRouteInDict(event event: E?, fromState: S, toState: S, userInfo: Any? = nil) -> Bool
    {
        let validTransitions = _validTransitions(fromState: fromState, toState: toState)

        for validTransition in validTransitions {

            var routeDicts: [_RouteDict] = []

            if let event = event {
                for (ev, routeDict) in self._routes {
                    if ev.rawValue == event || ev == .Any {
                        routeDicts += [routeDict]
                    }
                }
            }
            else {
                //
                // NOTE:
                // If `event` is `nil`, it means state-based-transition,
                // and all registered event-based-routes will be examined.
                //
                routeDicts += self._routes.values.lazy
            }

            for routeDict in routeDicts {
                if let keyConditionDict = routeDict[validTransition] {
                    for (_, condition) in keyConditionDict {
                        if _canPassCondition(condition, forEvent: event, fromState: fromState, toState: toState, userInfo: userInfo) {
                            return true
                        }
                    }
                }
            }
        }

        return false
    }

    /// Check for `_routeMappings`.
    private func _hasRouteMappingInDict(event event: E?, fromState: S, toState: S?, userInfo: Any? = nil) -> S?
    {
        for mapping in self._routeMappings.values {
            if let preferredToState = mapping(event: event, fromState: fromState, userInfo: userInfo)
                where preferredToState == toState || toState == nil
            {
                return preferredToState
            }
        }

        return nil
    }

    //--------------------------------------------------
    // MARK: - tryEvent
    //--------------------------------------------------

    /// - Returns: Preferred-`toState`.
    public func canTryEvent(event: E, userInfo: Any? = nil) -> S?
    {
        // check for `_routes`
        for case let routeDict? in [self._routes[.Some(event)], self._routes[.Any]] {
            for (transition, keyConditionDict) in routeDict {
                if transition.fromState == .Some(self.state) || transition.fromState == .Any {
                    for (_, condition) in keyConditionDict {
                        // if toState is `.Any`, always treat as identity transition
                        let toState = transition.toState.rawValue ?? self.state

                        if _canPassCondition(condition, forEvent: event, fromState: self.state, toState: toState, userInfo: userInfo) {
                            return toState
                        }
                    }
                }
            }
        }

        // check for `_routeMappings`
        if let toState = _hasRouteMappingInDict(event: event, fromState: self.state, toState: nil, userInfo: userInfo) {
            return toState
        }

        return nil
    }

    public func tryEvent(event: E, userInfo: Any? = nil) -> Bool
    {
        let fromState = self.state

        if let toState = self.canTryEvent(event, userInfo: userInfo) {

            // collect valid handlers before updating state
            let validHandlerInfos = self._validHandlerInfos(event: event, fromState: fromState, toState: toState)

            // update state
            self._state = toState

            // perform validHandlers after updating state.
            for handlerInfo in validHandlerInfos {
                handlerInfo.handler(Context(event: event, fromState: fromState, toState: toState, userInfo: userInfo))
            }

            return true
        }
        else {
            for handlerInfo in self._errorHandlers {
                let toState = self.state    // NOTE: there's no `toState` for failure of event-based-transition
                handlerInfo.handler(Context(event: event, fromState: fromState, toState: toState, userInfo: userInfo))
            }

            return false
        }
    }

    private func _validHandlerInfos(event event: E, fromState: S, toState: S) -> [_HandlerInfo<S, E>]
    {
        let validHandlerInfos = [ self._handlers[.Some(event)], self._handlers[.Any] ]
            .filter { $0 != nil }
            .map { $0! }
            .flatten()

        return validHandlerInfos.sort { info1, info2 in
            return info1.order < info2.order
        }
    }

    //--------------------------------------------------
    // MARK: - Route
    //--------------------------------------------------

    // MARK: addRoutes(event:)

    public func addRoutes(event event: E, transitions: [Transition<S>], condition: Machine.Condition? = nil) -> Disposable
    {
        return self.addRoutes(event: .Some(event), transitions: transitions, condition: condition)
    }

    public func addRoutes(event event: Event<E>, transitions: [Transition<S>], condition: Machine.Condition? = nil) -> Disposable
    {
        let routes = transitions.map { Route(transition: $0, condition: condition) }
        return self.addRoutes(event: event, routes: routes)
    }

    public func addRoutes(event event: E, routes: [Route<S, E>]) -> Disposable
    {
        return self.addRoutes(event: .Some(event), routes: routes)
    }

    public func addRoutes(event event: Event<E>, routes: [Route<S, E>]) -> Disposable
    {
        // NOTE: uses `map` with side-effects
        let disposables = routes.map { self._addRoute(event: event, route: $0) }

        return ActionDisposable {
            disposables.forEach { $0.dispose() }
        }
    }

    internal func _addRoute(event event: Event<E> = .Any, route: Route<S, E>) -> Disposable
    {
        let transition = route.transition
        let condition = route.condition

        let key = _createUniqueString()

        if self._routes[event] == nil {
            self._routes[event] = [:]
        }

        var routeDict = self._routes[event]!
        if routeDict[transition] == nil {
            routeDict[transition] = [:]
        }

        var keyConditionDict = routeDict[transition]!
        keyConditionDict[key] = condition
        routeDict[transition] = keyConditionDict

        self._routes[event] = routeDict

        let _routeID = _RouteID(event: event, transition: transition, key: key)

        return ActionDisposable { [weak self] in
            self?._removeRoute(_routeID)
        }
    }

    // MARK: addRoutes(event:) + conditional handler

    public func addRoutes(event event: E, transitions: [Transition<S>], condition: Condition? = nil, handler: Handler) -> Disposable
    {
        return self.addRoutes(event: .Some(event), transitions: transitions, condition: condition, handler: handler)
    }

    public func addRoutes(event event: Event<E>, transitions: [Transition<S>], condition: Condition? = nil, handler: Handler) -> Disposable
    {
        let routes = transitions.map { Route(transition: $0, condition: condition) }
        return self.addRoutes(event: event, routes: routes, handler: handler)
    }

    public func addRoutes(event event: E, routes: [Route<S, E>], handler: Handler) -> Disposable
    {
        return self.addRoutes(event: .Some(event), routes: routes, handler: handler)
    }

    public func addRoutes(event event: Event<E>, routes: [Route<S, E>], handler: Handler) -> Disposable
    {
        let routeDisposable = self.addRoutes(event: event, routes: routes)
        let handlerDisposable = self.addHandler(event: event, handler: handler)

        return ActionDisposable {
            routeDisposable.dispose()
            handlerDisposable.dispose()
        }
    }

    // MARK: removeRoute

    private func _removeRoute(_routeID: _RouteID<S, E>) -> Bool
    {
        guard let event = _routeID.event else { return false }

        let transition = _routeID.transition

        if let routeDict_ = self._routes[event] {
            var routeDict = routeDict_

            if let keyConditionDict_ = routeDict[transition] {
                var keyConditionDict = keyConditionDict_

                keyConditionDict[_routeID.key] = nil
                if keyConditionDict.isEmpty == false {
                    routeDict[transition] = keyConditionDict
                }
                else {
                    routeDict[transition] = nil
                }
            }

            if routeDict.isEmpty == false {
                self._routes[event] = routeDict
            }
            else {
                self._routes[event] = nil
            }

            return true
        }

        return false
    }

    //--------------------------------------------------
    // MARK: - RouteMapping
    //--------------------------------------------------

    // MARK: addRouteMapping

    public func addRouteMapping(routeMapping: RouteMapping) -> Disposable
    {
        let key = _createUniqueString()

        self._routeMappings[key] = routeMapping

        let routeMappingID = _RouteMappingID(key: key)

        return ActionDisposable { [weak self] in
            self?._removeRouteMapping(routeMappingID)
        }
    }

    // MARK: addRouteMapping + conditional handler

    public func addRouteMapping(routeMapping: RouteMapping, order: HandlerOrder = _defaultOrder, handler: Machine.Handler) -> Disposable
    {
        let routeDisposable = self.addRouteMapping(routeMapping)

        let handlerDisposable = self._addHandler(event: .Any, order: order) { context in

            guard let preferredToState = routeMapping(event: context.event, fromState: context.fromState, userInfo: context.userInfo)
                where preferredToState == context.toState else
            {
                return
            }

            handler(context)
        }

        return ActionDisposable {
            routeDisposable.dispose()
            handlerDisposable.dispose()
        }
    }

    // MARK: removeRouteMapping

    private func _removeRouteMapping(routeMappingID: _RouteMappingID) -> Bool
    {
        if self._routeMappings[routeMappingID.key] != nil {
            self._routeMappings[routeMappingID.key] = nil
            return true
        }
        else {
            return false
        }
    }

    //--------------------------------------------------
    // MARK: - Handler
    //--------------------------------------------------

    // MARK: addHandler(event:)

    public func addHandler(event event: E, order: HandlerOrder = _defaultOrder, handler: Machine.Handler) -> Disposable
    {
        return self.addHandler(event: .Some(event), order: order, handler: handler)
    }

    public func addHandler(event event: Event<E>, order: HandlerOrder = _defaultOrder, handler: Machine.Handler) -> Disposable
    {
        return self._addHandler(event: event, order: order) { context in
            // skip if not event-based transition
            guard let triggeredEvent = context.event else {
                return
            }

            if triggeredEvent == event.rawValue || event == .Any {
                handler(context)
            }
        }
    }

    private func _addHandler(event event: Event<E>, order: HandlerOrder = _defaultOrder, handler: Handler) -> Disposable
    {
        if self._handlers[event] == nil {
            self._handlers[event] = []
        }

        let key = _createUniqueString()

        var handlerInfos = self._handlers[event]!
        let newHandlerInfo = _HandlerInfo<S, E>(order: order, key: key, handler: handler)
        _insertHandlerIntoArray(&handlerInfos, newHandlerInfo: newHandlerInfo)

        self._handlers[event] = handlerInfos

        let handlerID = _HandlerID<S, E>(event: event, transition: .Any => .Any, key: key) // NOTE: use non-`nil` transition

        return ActionDisposable { [weak self] in
            self?._removeHandler(handlerID)
        }
    }

    // MARK: addErrorHandler

    public func addErrorHandler(order order: HandlerOrder = _defaultOrder, handler: Handler) -> Disposable
    {
        let key = _createUniqueString()

        let newHandlerInfo = _HandlerInfo<S, E>(order: order, key: key, handler: handler)
        _insertHandlerIntoArray(&self._errorHandlers, newHandlerInfo: newHandlerInfo)

        let handlerID = _HandlerID<S, E>(event: nil, transition: nil, key: key)  // NOTE: use `nil` transition

        return ActionDisposable { [weak self] in
            self?._removeHandler(handlerID)
        }
    }

    // MARK: removeHandler

    private func _removeHandler(handlerID: _HandlerID<S, E>) -> Bool
    {
        if let event = handlerID.event {
            if let handlerInfos_ = self._handlers[event] {
                var handlerInfos = handlerInfos_

                if _removeHandlerFromArray(&handlerInfos, removingHandlerID: handlerID) {
                    self._handlers[event] = handlerInfos
                    return true
                }
            }
        }
        // `transition = nil` means errorHandler
        else if handlerID.transition == nil {
            if _removeHandlerFromArray(&self._errorHandlers, removingHandlerID: handlerID) {
                return true
            }
            return false
        }

        return false
    }

}

//--------------------------------------------------
// MARK: - Custom Operators
//--------------------------------------------------

// MARK: `<-!` (tryEvent)

infix operator <-! { associativity left }

public func <-! <S: StateType, E: EventType>(machine: Machine<S, E>, event: E) -> Machine<S, E>
{
    machine.tryEvent(event)
    return machine
}

public func <-! <S: StateType, E: EventType>(machine: Machine<S, E>, tuple: (E, Any?)) -> Machine<S, E>
{
    machine.tryEvent(tuple.0, userInfo: tuple.1)
    return machine
}

//--------------------------------------------------
// MARK: - HandlerOrder
//--------------------------------------------------

/// Precedence for registered handlers (higher number is called later).
public typealias HandlerOrder = UInt8

internal let _defaultOrder: HandlerOrder = 100

//--------------------------------------------------
// MARK: - Internal
//--------------------------------------------------

// generate approx 126bit random string
internal func _createUniqueString() -> String
{
    var uniqueString: String = ""
    for _ in 1...8 {
        uniqueString += String(UnicodeScalar(_random(0xD800))) // 0xD800 = 55296 = 15.755bit
    }
    return uniqueString
}

internal func _validTransitions<S: StateType>(fromState fromState: S, toState: S) -> [Transition<S>]
{
    return [
        fromState => toState,
        fromState => .Any,
        .Any => toState,
        .Any => .Any
    ]
}

internal func _canPassCondition<S: StateType, E: EventType>(condition: Machine<S, E>.Condition?, forEvent event: E?, fromState: S, toState: S, userInfo: Any?) -> Bool
{
    return condition?((event, fromState, toState, userInfo)) ?? true
}

internal func _insertHandlerIntoArray<S: StateType, E: EventType>(inout handlerInfos: [_HandlerInfo<S, E>], newHandlerInfo: _HandlerInfo<S, E>)
{
    var index = handlerInfos.count

    for i in Array(0..<handlerInfos.count).reverse() {
        if handlerInfos[i].order <= newHandlerInfo.order {
            break
        }
        index = i
    }

    handlerInfos.insert(newHandlerInfo, atIndex: index)
}

internal func _removeHandlerFromArray<S: StateType, E: EventType>(inout handlerInfos: [_HandlerInfo<S, E>], removingHandlerID: _HandlerID<S, E>) -> Bool
{
    for i in 0..<handlerInfos.count {
        if handlerInfos[i].key == removingHandlerID.key {
            handlerInfos.removeAtIndex(i)
            return true
        }
    }

    return false
}
