//
//  ContentView.swift
//  StreamsExample
//
//  Created by Sebastian Buys on 10/20/21.
//

import SwiftUI
import Combine

class MyViewModel: ObservableObject {
    /*
     disposeBag is a place to store our subscriptions.
     You'll also see it declared like this in our example code:
     var subscriptions = Set<AnyCancellable>()
     
     The naming convention "disposeBag" 🗑 comes from other reactive frameworks.
     I like using this name because it's a good analogy for what's going on:
     When your view / view model is deinitialized and removed from memory,
     the system will dispose of the subscriptions stored here.
    */
    private var disposeBag: Set<AnyCancellable> = []
    
    // The @published attribute turns my property into a publisher
    @Published var count: Int = 0
    @Published var doubleCount: Int = 0
    
    /*
     PassthroughSubject is a stream that just passes values through like a signal.
     You can subscribe to the signal when it is emitted, but that value isn't stored.
     You can't read the value outside of the stream.
     */
    var tripleCountSignal: PassthroughSubject<Int, Never> = PassthroughSubject()
    
    // CurrentValueSubject is also a stream, but it DOES store the most recent value emitted.
    // Notice how it has to be initialized with a value, unlike PassthroughSubject
    var tripleCount: CurrentValueSubject<Int, Never> = CurrentValueSubject(0)
    
    init() {
        /*
         Demonstrating different ways to work with streams
         */
        
        /*
         ASSIGN EXAMPLE:
         Map my count value from value -> value * 2.
         Assign the new stream of values to doubleCount
        */
        $count.map { $0 * 2 }
            .assign(to: &self.$doubleCount)
        
        
        /*
         SINK EXAMPLE:
         Map my count value from value -> value * 3 and then sink.
         
         You can think of sink as a kind of drain or sink hole 🕳 🚰.
         The stream drains into closure, where I can do whatever with it.
         In this case I'll just redirect it to my other streams
        */

        $count.map { $0 * 3 }
            .sink { countTimeThree in
                // Send to PassthroughSubject
                self.tripleCountSignal.send(countTimeThree)
                
                // Send to CurrentValueSubject
                self.tripleCount.send(countTimeThree)
            }.store(in: &disposeBag)


        // Silly example chaining multiple operators:
        // First create an array filled with emojis
        let integerCodes: [Int] =  Array(0x1F601...0x1F64F)
        let emojis = integerCodes.compactMap {
            // Create unicode scalar
            UnicodeScalar($0)
        }.map {
            String($0)
        }
        
        $count.map { $0 * 2 } // Multiply by 2. Value is still an integer
            .map { $0 + 1 } // Add 1. Value is still an integer.
            .map {
                let index = $0 % emojis.count
                return emojis[index]
            } // Create character from int and perform string interpolation. Value is now a string
            .sink {
                print("After lots of mapping, the value is:", $0)
            }.store(in: &disposeBag)

        
        // Example - Debounce a stream
        $count.debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { count in
                print("🟢 Debounced: \(count)")
            }.store(in: &disposeBag)
        
        // Example - Throttle a stream
        $count.throttle(for: .seconds(0.5), scheduler: RunLoop.main, latest: true)
            .sink { count in
                print("🔵 Throttled: \(count)")
            }.store(in: &disposeBag)

    }
}

struct ContentView: View {
    @StateObject var viewModel = MyViewModel()
    
    var body: some View {
        VStack {
            // Button for incrementing my counter
            Button("Increase count 👆") {
                viewModel.count += 1
            }.padding()
            
            Text("Count is: \(viewModel.count)").padding()
            
            Text("Double count is: \(viewModel.doubleCount)").padding()
            
            Text("Triple count is: \(viewModel.tripleCount.value)").padding()
            
            // For simple data manipulation, I can do my math directly in the view:
            Text("Quadruple count is: \(viewModel.count * 4)").padding()
            
        }.onReceive(viewModel.$count) { value in
            /*
             The onReceive function takes the publisher I want to subscribe to,
             and an action (closure) to call when the publisher emits a new value.
             Here I've given the closure argument the name "value"
             */

            print("🙋‍♀️ Count is: \(value)")
        }.onReceive(viewModel.$count) {
            /*
             This time I'll use the shorthand argument $0,
             instead of giving the closure argument a name
             */
            print("🙋‍♂️ Count is: \($0)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
