import SwiftState

postfix operator <=< { }

postfix func <=< <T: StateType>(state: T) -> Transition<T> {
	return state => state
}

//
enum RecorderState: StateType {
	case Starting, FirstRecording, Ready, Waiting, Recording
}

enum RecorderEvent: EventType {
	case StartRecording, StopRecording, LoopRecording, LoopPlayback
}

//
let recorderMachine =
	StateMachine<RecorderState, RecorderEvent> (state: .Starting) {
		(recorderMachine: StateMachine) in

		recorderMachine.addRoutes(event: .StartRecording, transitions: [
			.Starting => .FirstRecording,
			.Ready => .Waiting,
			])
		recorderMachine.addRoutes(event: .StopRecording, transitions: [
			.FirstRecording => .Ready,
			.Recording => .Ready,
			.Waiting => .Ready,
			])
		recorderMachine.addRoutes(event: .LoopRecording, transitions: [
			.Recording => .Recording
			])

		recorderMachine.addRoutes(event: .LoopPlayback,
		                          transitions: [
			.Ready<=<,
			.Waiting<=<,
			.Recording<=<,
			.Waiting => .Recording,
			])

		//
		recorderMachine.addHandler(event: .StartRecording) { context in
			print("Start\t\t" +
				  "\(context.fromState)  =>  \(context.toState)")
		}

		recorderMachine.addHandler(event: .StopRecording) { context in
			print("Stop\t\t" +
				  "\(context.fromState)  =>  \(context.toState)")
		}

		recorderMachine.addHandler(event: .LoopRecording) { context in
			print("Loop Rec\t" +
				  "\(context.fromState)  =>  \(context.toState)")
		}

		recorderMachine.addHandler(event: .LoopPlayback) { context in
			print("Loop Play\t" +
				"\(context.fromState)  =>  \(context.toState)")
		}

		//
		recorderMachine.addErrorHandler { event, fromState, toState, userInfo in
			print("[ERROR (\(userInfo))] \(fromState) ==\(event)=> \(toState)")
		}
}
