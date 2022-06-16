import UIKit
import Combine

//Combine

// Is a declarative, reactive framework for processing events over time.

//Publishers
// Publishers are types that can emit values over time, every publisher can emit multiple events of 3 types:
// - An output value of the publisher's generic output type
// - A succesful completion
// - Acompletion with an error of the pusblishers failure type

//Operators
// Methods declared on the Publisher protocol that can return the same or a new publisher.
// You can call a bunch of operators one after the other and chain them together.
// Something that is important to take note is that the operator always will have an input and an output, commonly referred as upstream and downstream
// This helps to no other asyncrhonous running piece of code can jump in and change the data we are working on.

//Subscribers
// The end of the subscription chain, every subscription ends with a subscriber, they usually do something with the emitted ouptut or with completion events.
// Combine provide two built in subscribers:
// - Sink: Allows you to provide closures to your code that will receive output values and completions.
// - Assign: Allows you to bind the resulting ouptut to some property on your model or your UI to display the data directly on screen.



public func example(of description: String,
                    action: () -> Void) {
  print("\n——— Example of:", description, "———")
  action()
}

// Here we are only creating a publisher that will emit a notification
example(of: "Publisher") {
    // 1
    let myNotification = Notification.Name("MyNotification")
    
    // 2
    let publisher = NotificationCenter.default.publisher(for: myNotification, object: nil)
    
    // This is how it was done before
//    // 3
//    let center = NotificationCenter.default
//
//    // 4
//    let observer = center.addObserver(forName: myNotification,
//                                      object: nil,
//                                      queue: nil) { notification in
//        print("notification received!")
//    }
//    // 5
//    center.post(name: myNotification, object: nil)
//
//    // 6
//    center.removeObserver(observer)
        
}

example(of: "Subscriber") {
    let myNotification = Notification.Name("MyNotification")
    let center = NotificationCenter.default
    let publisher = center.publisher(for: myNotification, object: nil)
    
    // 1
    let subscription = publisher.sink { _ in
        print("Notification received from a publisher!")
    }
    //2
    center.post(name: myNotification, object: nil)
    // 3
    subscription.cancel()
}

// Just will emit an output to the subscriber just once and then the stream is finished.

example(of: "Just") {
    // 1
    let just = Just("Hello world!")
    
    // 2
    _ = just.sink(
        receiveCompletion: {
            print("Received completion", $0)
    }, receiveValue: {
            print("Received value", $0)
    })
    
    _ = just.sink { value in
        print("Received value 2", value)
    }
    
}

// The assign(to:on:) operator enables us to assign the received value to a KVO-compliant property of an object
// documentation: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVOCompliance.html
//KVO stands for Key-Value observing, principally is a technique for observing the program state changes, KVO allows other objects to establish surveillance on changes for any instance variables that we have.
example(of: "assign(to:on:)") {
    // 1
    class SomeObject {
        var value: String = "" {
            didSet {
                print(value)
            }
        }
    }
    
    // 2
    let object = SomeObject()
    
    // 3
    let publisher = ["Hello", "world!"].publisher
    
    // 4
    publisher.assign(to: \.value, on: object)
    
    
    
}

example(of: "assign(to:)") {
    // 1
    class SomeObject {
        @Published var value = 0
    }
    
    let object = SomeObject()
    
    // 2
    object.$value.sink { print($0) }
    
    //3
    (0..<10).publisher
        .assign(to: &object.$value)
    
    object.value = 100
}


// Subjects
// Subjects can be seen as custom publishers, that are easier to work with.
// we have 2 types of subjects PassthroughSubject and CurrentValueSubject



// PassthroughSubject
// PassthroughSubject will emit elements to subscribers this type of subject only passes through values meaning that it does not capture any state and will drop values if ther aren't any subscribers set

example(of: "PassthroughSubject") {
  // 1
    struct ChatRoom {
        enum Error: Swift.Error {
            case missingConnection
        }
        let subject = PassthroughSubject<String,Error>()
        
        func simulateMessage() {
            subject.send("Hello!")
        }
        
        func simulateNetworkError() {
            subject.send(completion: .failure(.missingConnection))
        }
        
        func closeRoom() {
            subject.send("Chat room closed")
            subject.send(completion: .finished)
        }
    }
    // Create a new chatroom
    let chatRoom = ChatRoom()
    
    //Subscribe into chatroom subject and listen to events
    chatRoom.subject.sink { completion in
        switch completion {
        case .finished:
            print("Received finished")
        case .failure(let error):
            print("Received error: \(error)")
        }
    } receiveValue: { message in
        print("Received message: \(message)")
    }
    
    //Send events to see how the subscriber react
    //chatRoom.simulateNetworkError()
    chatRoom.simulateMessage()
    //chatRoom.closeRoom()
    chatRoom.subject.send("iOS Bootcamp")
}

//CurrentValueSubject
// A currentValueSubject is initialized with an initial value. The new subscribers will receive this initial value upon subscribing.

example(of: "CurrentValueSubject") {
    struct Uploader {
        enum State {
            case pending, uploading, terminated
        }
        
        enum Error: Swift.Error {
            case uploadFailed
        }
        
        //Subject == Custom Publisher
        let subject = CurrentValueSubject<State, Error>(.pending)
        
        func startUpload() {
            subject.send(.uploading)
        }
        
        func finishUpload() {
            subject.value = .terminated
            subject.send(completion: .finished)
        }
        
        func failUpload() {
            subject.send(completion: .failure(.uploadFailed))
        }
    }
    
    let uploader = Uploader()
    
    uploader.subject.sink { completion in
        switch completion {
        case .finished:
            print("Upload finished")
        case .failure(let error):
            print("Upload failed with error: \(error)")
        }
    } receiveValue: { message in
        print("Received message: \(message)")
    }
    
//    uploader.startUpload()
//    uploader.finishUpload()
    
    uploader.failUpload()
}

// Operators
// Operators will let you update the information inside of the stream before it gets into the subscriber

//We have 5 type of operators:
// - Transforming operators: Use this operators to manipulate the values of the publishers to the way the subscribers need them.
// - Filtering operators: This operators will let you limit the number of values or events emited by the publisher.
// - Combining operators: This operators will let you as it name says combine values from different publishers so you can do very powerful stuff with them.
// - Time manipulation operators:
// - Sequence operators: will let you manage the values of the publishers when the publisher is sending a lot of values


// Transforming operators:

example(of: "Map operator") {
    
    class MapOperator {
        @Published var message = "Example"
    }
    
    let mapOperator = MapOperator()
    
    mapOperator.$message.sink { value in
        print(value)
    }
    
    mapOperator
        .$message
        .map { "This is an \($0)" }
        .sink { message in
        print(message)
    }
    
    mapOperator.message = "example 2"
}

// Filtering operators
example(of: "filter") {
  // 1
  let numbers = (1...10).publisher
  
  // 2
  numbers
    .filter { $0.isMultiple(of: 3) }
    .sink(receiveValue: { n in
      print("\(n) is a multiple of 3!")
    })
   
}

// Combining operators
example(of: "append(Output...)") {
  // 1
  let publisher = [1].publisher

  // 2
  publisher
    .append(2, 3)
    .append(4)
    .sink(receiveValue: {
        print($0) })
}

// Sequence operators

example(of: "min") {
  // 1
  let publisher = [1, -50, 246, 0].publisher

  // 2
  publisher
    .print("publisher")
    .min()
    .sink(receiveValue: { print("Lowest value is \($0)") })
}





