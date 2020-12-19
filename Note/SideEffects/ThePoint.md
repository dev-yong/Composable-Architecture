# Side Effets: The Point

### [Introduction](https://www.pointfree.co/collections/composable-architecture/side-effects/ep79-effectful-state-management-the-point#t5)

- 가장 복잡한 asyncrhonous side effect를  추출하였다. 
- 하지만 몇 가지의 이유로 인하여 이 effect는 더욱 복잡해 졌다.
  - 이전에는 고려하지 않았던 alert의 표시와 해제와 결합되어져 있다.
    - 이 문제를 해결하려면 alert의 표시와 관련된 local state를 추출하는 것이 의미하는 바, 바인딩 관리 방법, 해제 등을 고려해야했다.
  - 그 effect가 asynchronous하기 때문이다. 
    - Asynchronous는 synchronous effect보다 본질적으로 더 복잡하다.
    - Threading 문제를 고려해야했지만, 이것은 View에서 ObservableObject로 로직을 추출하는 모든 사람이 직면하게되는 문제이다. 고로, 아키텍쳐의 결함이 아니다. 
- 새로운 Effect는 Parallel과 같은 모양으로, 다른 사람에게 함수를 전달하고, 작업을 수행하고 준비가되면 해당 함수를 호출한다.
- Strore에 다시 피드백될 수 있는 배열로 effect를 반환할 수 있는 Reducer를 가지고 있다.
- Unidirectional data flow를 수용할 수 있게 되었다.
  - Effect와 asynchronicity에 의하여 발생하는 복잡성이 있지만, 어떻게 데이터가 어플리케이션을 통과하는 지에 대하여 추론할 수 있다.
  - Effect는 오로지 store를 통하여 다시 전송되는 action을 통해서만 app의 state를 변경한다 
- Side-effect 코드가 view의 clousre에 존재하는 것이 아니라, 이제는 reducer의 closure 안에 존재한다.

### [Composable, transformable effects](https://www.pointfree.co/collections/composable-architecture/side-effects/ep79-effectful-state-management-the-point#t253)

- `(@escaping (A) -> Void) -> Void`  의 signature를 감싸는 struct를 만든다.
- Effect는 일부 callback 함수를 통해 async적으로 수행 할 수있는 작업 단위이다.
- 그리고 `map`  operation을 지원하여 effect에 의해 생성되는 값을 다른 값으로 쉽게 변환 할 수 있다.

```swift
public struct Effect<A> {
  public let run: (@escaping (A) -> Void) -> Void

  public init(run: @escaping (@escaping (A) -> Void) -> Void) {
    self.run = run
  }

  public func map<B>(_ f: @escaping (A) -> B) -> Effect<B> {
    return Effect<B> { callback in self.run { a in callback(f(a)) }
  }
}
```

- Wolfram Alpha를 처리하기위한 라이브러리 코드가 여전히 Effect 유형을 사용하는 대신 콜백 세계에 살고 있으며,  Wolfram API와의 상호 작용과 관련이없는 몇 가지 보편적인 것들과 Wolfram 특정 도메인에 해당하는 URLSession의 요청, JSON 디코딩이 혼합되어 있다.

### [Reusable effects: network requests](https://www.pointfree.co/collections/composable-architecture/side-effects/ep79-effectful-state-management-the-point#t676)

- Wolfram에 대한 것이 Effect 타입으로 표현되는 것은 좋지만 작업의 단위를 더욱 쉽게 분해할 수 있다.

```swift
public typealias DataTaskResopnse = (Data?, URLResponse?, Error?)

extension URLSession {
    
    public func dataTask(request: URL) -> Effect<DataTaskResopnse> {
      return Effect { callback in
        self.dataTask(with: request) { data, response, error in
          callback((data, response, error))
        }.resume()
      }
    }

}

extension Effect where A == DataTaskResopnse {
    
    public func decode<B: Decodable, D: TopLevelDecoder>(
        as type: B.Type,
        using decoder: D
    ) -> Effect<B?> where D.Input == Data {
    return self.map { data, _, _ in
      data
        .flatMap { try? decoder.decode(B.self, from: $0) }
    }
  }
    
}
```

### [Reusable effects: threading](https://www.pointfree.co/collections/composable-architecture/side-effects/ep79-effectful-state-management-the-point#t1022)

- `nthPrime(count).map { CounterAction.nthPrimeResponse($0) }`  는 action을 보낼 때, main에서 수행하도록 할 수가 없다.

```swift
public func receive(on queue: DispatchQueue) -> Effect {
        return Effect { callback in
            self.run { a in queue.async { callback(a) }
            }
        }
    }
```

### [Getting everything building again](https://www.pointfree.co/collections/composable-architecture/side-effects/ep79-effectful-state-management-the-point#t1259)

