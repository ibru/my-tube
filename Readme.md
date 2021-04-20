This repository proposes an app architecture for medium-sized iOS apps based on latest trends as of 2021. It features:

# SwiftUI + MVVM + Redux + Clean Architecture + Combine

This sample app is not meant to be super finished and code is not super clean. It is just to explore concepts of the architecture.

Feedback of any type is very welcome!

## What this code does

It is a little unfinished app which is using YouTube Data API to search for YouTube videos, shows detail of video and allows it to favorite it (save to local DB).

To be able to load the API requests successfully, you’ll have to register your YouTube Data account and provide the correct API key.

I didnt care about UI that much. It is unfinished and often uses dummy data. And it's not that important for the purpose I'm trying to achieve here.

## High level architecture overview

### Presentation Layer

UI layer consist of SwiftUI views which are using ViewModels and observe its `@Published` properties.

ViewModels internally operate on a `State` which however contains business logic models (Entities) that are not suitable to hand over directly to Views. Instead, ViewModels should format State data in a way their View exactly needs it.

### Domain Layer

Main logic inside ViewModels is driven using Redux-style state machine. Big thanks for this belongs to guys from [Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) from which I took implementation of `Store`, `Reducer`, `Feedback` and I did some minor changes.

ViewModels are initialized by providing `Store` which drives app logic for particular ViewModel State and Actions. 

The `Store` is given some dependencies provided by `Environment` struct. These dependencies try to follow [Clean Architecture principles](https://tech.olx.com/clean-architecture-and-mvvm-on-ios-c9d167d9f5b3), so they should consist of `UseCases` which operate on business logic `Entities` and have injected dependencies for `Repositories`

### Data layer

Data layer contains most low level code (Repositories) which are responsible for running API requests, communicating to local DB etc. I paid only minor attention to this layer because my aim was not to focus much on details of where data are stored or taken from. It’s there just to explore how it works in terms of dependency injection and testability.


## Concepts

Various concepts that might be interesting to think about:

### Creating child stores/states/reducers

For Redux-style state machine I’ve basically copy-pasted `Store`, `Reducer`, `Feedback`  classes from Composable Architecture and did minor adjustments, mostly commented out unneeded code.

The notable change I made was that I created new `Store.scope` method:

```swift
public func scope<LocalState, LocalAction, LocalEnvironment>(
    toLocalState: @escaping (State) -> (LocalState),
    updateGlobalState: @escaping (inout State, LocalState) -> Void,
    environment: @autoclosure @escaping () -> LocalEnvironment,
    using reducer: Reducer<LocalState, LocalAction, LocalEnvironment>
) -> Store<LocalState, LocalAction> {
    let localStore = Store<LocalState, LocalAction>(
        initialState: toLocalState(self.state),
        reducer: {
            let effect = reducer.run(&$0, $1, environment())
            updateGlobalState(&self.state, $0)
            return effect
        }
    )
    localStore.parentCancellable = self.$state
        .sink { [weak localStore] newValue in
            localStore?.state = toLocalState(newValue)
        }

    return localStore
}
```

This method can operate between parend and child stores by using two transformations:
 1) `toLocalState` - derives child(local) state from parent(global) state
 2) `updateGlobalState` - updates parent(global) state in place based on changes inside child(local) state

When creating store scope like this, it allows me to:
- not being forced to decompose child stores based in KeyPath of parent stores (at least this seems to be a requirement of Composable Architecture)
- I can create and execute child state machine on-demand, when it’s actually needed. As opposed to Composable Architecture which is suggesting to `pullback` + `combine` many of small reducers into one huge reducer

I’m wondering why this kind of `scope` method is not part of Composable Architecture initially. But maybe I’m just missing some key concepts of Redux architectures. I had no prior knowledge of it before writing this code.

### Dependencies using Struct instead of Protocols

One of the interesting and (for me) controversial concepts I wanted to try out was to model dependencies using Structs not Protocols. I got motivated for this by talk [by Stephen Celis](https://www.pointfree.co/blog/posts/21-how-to-control-the-world) and Composable Architecture uses it and gives it the name `Environment` so I tried to follow same principles I’ve seen there.

To be hones so far I have mixed feelings about it. I’ll probably do a Draft PR which modifies code to pass dependencies using Protocols to really compare these two. Or anyone else could do the PR. Would you like give it a try?

### Testability

One of the key factors for me is ease of testability. Which usually tells how well are the code layers separated. So far it seems good to me.
I didn’t aim for a huge amount of test coverage. I just wanted to know how the tests can be written when dependencies are modeled as Structs.

In ViewModels tests I try to not rely test behavior on the fact that they use `Store`, `Reducers` etc. internally because it’s  an implementation detail. I want my tests to be still usable and saving my ass in case I would decide to switch from Redux to something else. The only elements which should play the role for ViewModels tests are the `@Published` properties, methods and `Environment` passing up mock dependencies.

## Reference Materials

- [Composable architecture](https://github.com/pointfreeco/swift-composable-architecture)

- [isowords iOS app](https://github.com/pointfreeco/isowords)

- [Clean architecture](https://tech.olx.com/clean-architecture-and-mvvm-on-ios-c9d167d9f5b3)

- [Composable Reducers & Effects Systems](https://www.youtube.com/watch?v=QOIigosUNGU)

- [How to Control the World](https://www.pointfree.co/blog/posts/21-how-to-control-the-world)

- [Modern MVVM iOS App Architecture with Combine and SwiftUI](https://www.vadimbulavin.com/modern-mvvm-ios-app-architecture-with-combine-and-swiftui/)



