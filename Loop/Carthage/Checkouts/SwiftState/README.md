SwiftState [![Circle CI](https://circleci.com/gh/ReactKit/SwiftState/tree/swift%2F2.0.svg?style=svg)](https://circleci.com/gh/ReactKit/SwiftState/tree/swift%2F2.0)
==========

Elegant state machine for Swift.

![SwiftState](Screenshots/logo.png)


## Example

```swift
enum MyState: StateType {
    case State0, State1, State2
}
```

```swift
// setup state machine
let machine = StateMachine<MyState, NoEvent>(state: .State0) { machine in
    
    machine.addRoute(.State0 => .State1)
    machine.addRoute(.Any => .State2) { context in print("Any => 2, msg=\(context.userInfo)") }
    machine.addRoute(.State2 => .Any) { context in print("2 => Any, msg=\(context.userInfo)") }
    
    // add handler (`context = (event, fromState, toState, userInfo)`)
    machine.addHandler(.State0 => .State1) { context in
        print("0 => 1")
    }
    
    // add errorHandler
    machine.addErrorHandler { event, fromState, toState, userInfo in
        print("[ERROR] \(fromState) => \(toState)")
    }
}

// initial
XCTAssertEqual(machine.state, MyState.State0)

// tryState 0 => 1 => 2 => 1 => 0

machine <- .State1
XCTAssertEqual(machine.state, MyState.State1)

machine <- (.State2, "Hello")
XCTAssertEqual(machine.state, MyState.State2)

machine <- (.State1, "Bye")
XCTAssertEqual(machine.state, MyState.State1)

machine <- .State0  // fail: no 1 => 0
XCTAssertEqual(machine.state, MyState.State1)
```

This will print:

```swift
0 => 1
Any => 2, msg=Optional("Hello")
2 => Any, msg=Optional("Bye")
[ERROR] State1 => State0
```

### Transition by Event

Use `<-!` operator to try transition by `Event` rather than specifying target `State`.

```swift
enum MyEvent: EventType {
    case Event0, Event1
}
```

```swift
let machine = StateMachine<MyState, MyEvent>(state: .State0) { machine in
    
    // add 0 => 1 => 2
    machine.addRoutes(event: .Event0, transitions: [
        .State0 => .State1,
        .State1 => .State2,
    ])
    
    // add event handler
    machine.addHandler(event: .Event0) { context in
        print(".Event0 triggered!")
    }
}

// initial
XCTAssertEqual(machine.state, MyState.State0)

// tryEvent
machine <-! .Event0
XCTAssertEqual(machine.state, MyState.State1)

// tryEvent
machine <-! .Event0
XCTAssertEqual(machine.state, MyState.State2)

// tryEvent (fails)
machine <-! .Event0
XCTAssertEqual(machine.state, MyState.State2, "Event0 doesn't have 2 => Any")
```

If there is no `Event`-based transition, use built-in `NoEvent` instead.

### State & Event enums with associated values

Above examples use _arrow-style routing_ which are easy to understand, but it lacks in ability to handle **state & event enums with associated values**. In such cases, use either of the following functions to apply _closure-style routing_:

- `machine.addRouteMapping(routeMapping)`
    - `RouteMapping`: `(event: E?, fromState: S, userInfo: Any?) -> S?`
- `machine.addStateRouteMapping(stateRouteMapping)`
    - `StateRouteMapping`: `(fromState: S, userInfo: Any?) -> [S]?`

For example:

```swift
enum StrState: StateType {
    case Str(String) ...
}
enum StrEvent: EventType {
    case Str(String) ...
}

let machine = Machine<StrState, StrEvent>(state: .Str("initial")) { machine in
    
    machine.addRouteMapping { event, fromState, userInfo -> StrState? in
        // no route for no-event
        guard let event = event else { return nil }
        
        switch (event, fromState) {
            case (.Str("gogogo"), .Str("initial")):
                return .Str("Phase 1")
            case (.Str("gogogo"), .Str("Phase 1")):
                return .Str("Phase 2")
            case (.Str("finish"), .Str("Phase 2")):
                return .Str("end")
            default:
                return nil
        }
    }
    
}

// initial
XCTAssertEqual(machine.state, StrState.Str("initial"))

// tryEvent (fails)
machine <-! .Str("go?")
XCTAssertEqual(machine.state, StrState.Str("initial"), "No change.")

// tryEvent
machine <-! .Str("gogogo")
XCTAssertEqual(machine.state, StrState.Str("Phase 1"))

// tryEvent (fails)
machine <-! .Str("finish")
XCTAssertEqual(machine.state, StrState.Str("Phase 1"), "No change.")

// tryEvent
machine <-! .Str("gogogo")
XCTAssertEqual(machine.state, StrState.Str("Phase 2"))

// tryEvent (fails)
machine <-! .Str("gogogo")
XCTAssertEqual(machine.state, StrState.Str("Phase 2"), "No change.")

// tryEvent
machine <-! .Str("finish")
XCTAssertEqual(machine.state, StrState.Str("end"))
```

This behaves very similar to JavaScript's safe state-container [rackt/Redux](https://github.com/rackt/redux), where `RouteMapping` can be interpretted as `Redux.Reducer`.

For more examples, please see XCTest cases.


## Features

- Easy Swift syntax
    - Transition: `.State0 => .State1`, `[.State0, .State1] => .State2`
    - Try state: `machine <- .State1`
    - Try state + messaging: `machine <- (.State1, "GoGoGo")`
    - Try event: `machine <-! .Event1`
- Highly flexible transition routing
    - Using `Condition`
    - Using `.Any` state
        - Entry handling: `.Any => .SomeState`
        - Exit handling: `.SomeState => .Any`
        - Blacklisting: `.Any => .Any` + `Condition`
    - Using `.Any` event
    
    - Route Mapping (closure-based routing): [#36](https://github.com/ReactKit/SwiftState/pull/36)
- Success/Error handlers with `order: UInt8` (more flexible than before/after handlers)
- Removable routes and handlers using `Disposable`
- Route Chaining: `.State0 => .State1 => .State2`
- Hierarchical State Machine: [#10](https://github.com/ReactKit/SwiftState/pull/10)


## Terms

Term          | Type                          | Description
------------- | ----------------------------- | ------------------------------------------
State         | `StateType` (protocol)        | Mostly enum, describing each state e.g. `.State0`.
Event         | `EventType` (protocol)        | Name for route-group. Transition can be fired via `Event` instead of explicitly targeting next `State`.
State Machine | `Machine`                     | State transition manager which can register `Route`/`RouteMapping` and `Handler` separately for variety of transitions.
Transition    | `Transition`                  | `From-` and `to-` states represented as `.State1 => .State2`. Also, `.Any` can be used to represent _any state_.
Route         | `Route`                       | `Transition` + `Condition`.
Condition     | `Context -> Bool`             | Closure for validating transition. If condition returns `false`, transition will fail and associated handlers will not be invoked.
Route Mapping | `(event: E?, fromState: S, userInfo: Any?) -> S?`                | Another way of defining routes **using closure instead of transition arrows (`=>`)**. This is useful when state & event are enum with associated values. Return value (`S?`) means preferred-`toState`, where passing `nil` means no routes available. See [#36](https://github.com/ReactKit/SwiftState/pull/36) for more info.
State Route Mapping | `(fromState: S, userInfo: Any?) -> [S]?`                | Another way of defining routes **using closure instead of transition arrows (`=>`)**. This is useful when state is enum with associated values. Return value (`[S]?`) means multiple `toState`s from single `fromState` (synonym for multiple routing e.g. `.State0 => [.State1, .State2]`). See [#36](https://github.com/ReactKit/SwiftState/pull/36) for more info.
Handler       | `Context -> Void`             | Transition callback invoked when state has been changed successfully.
Context       | `(event: E?, fromState: S, toState: S, userInfo: Any?)` | Closure argument for `Condition` & `Handler`.
Chain         | `TransitionChain` / `RouteChain` | Group of continuous routes represented as `.State1 => .State2 => .State3`


## Related Articles

1. [Swiftで有限オートマトン(ステートマシン)を作る - Qiita](http://qiita.com/inamiy/items/cd218144c90926f9a134) (Japanese)
2. [Swift+有限オートマトンでPromiseを拡張する - Qiita](http://qiita.com/inamiy/items/d3579b55a3ecc28dde63) (Japanese)


## Licence

[MIT](LICENSE)
