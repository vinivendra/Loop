import SwiftState

enum RecorderState: StateType {
	case Starting, FirstRecording, Ready, Waiting, Recording
}

enum RecorderEvent: EventType {
	case StartRecording, StopRecording, LoopRecording
}

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
			])
		recorderMachine.addRoutes(event: .LoopRecording, transitions: [
			.Waiting => .Recording,
			.Any => .Any,
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
			print("Loop\t\t" +
				  "\(context.fromState)  =>  \(context.toState)")
		}

		//
		recorderMachine.addErrorHandler { event, fromState, toState, userInfo in
			print("[ERROR (\(userInfo))] \(fromState) ==\(event)=> \(toState)")
		}
}
