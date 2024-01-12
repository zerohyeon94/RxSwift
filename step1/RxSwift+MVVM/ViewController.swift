//
//  ViewController.swift
//  RxSwift+MVVM
//
//  Created by iamchiwon on 05/08/2019.
//  Copyright © 2019 iamchiwon. All rights reserved.
//

import RxSwift
import SwiftyJSON
import UIKit

let MEMBER_LIST_URL = "https://my.api.mockaroo.com/members_with_avatar.json?key=44ce18f0"

// RxSwift는 completion이 아닌 return값으로 받기위해서 만들어진 유틸리티다.

// 옵저버블의 형태
class ObservableSelf<T> {
    private let task: (@escaping (T) -> Void) -> Void
    
    init(task: @escaping (@escaping (T) -> Void) -> Void) {
        self.task = task
    }
    
    func subscribe(_ f: @escaping (T) -> Void) {
        task(f)
    }
}

class ViewController: UIViewController {
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var editView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.timerLabel.text = "\(Date().timeIntervalSince1970)"
        }
    }
    
    private func setVisibleWithAnimation(_ v: UIView?, _ s: Bool) {
        guard let v = v else { return }
        UIView.animate(withDuration: 0.3, animations: { [weak v] in
            v?.isHidden = !s
        }, completion: { [weak self] _ in
            self?.view.layoutIfNeeded()
        })
    }
    
    // @escaping이 필요한 이유: 함수가 반환된 후에 클로저가 호출될 때 클로저 매게변수에 '@escaping'을 써야한다. 클로저가 함수를 탈출한다는 것이다. '@escaping'으로 컴파일러에게 클로저가 함수의 범위를 벗어나도록 허용하도록 알려주는 것
    //    func downloadJson(_ url: String, _ completion: @escaping (String?) -> Void){
    //        DispatchQueue.global().async {
    //            let url = URL(string: url)!
    //            let data = try! Data(contentsOf: url)
    //            let json = String(data: data, encoding: .utf8)
    //            DispatchQueue.main.async {
    //                completion(json)
    //            }
    //        }
    //    }
    
    // Observable의 생명주기
    // 1. Create
    // 2. Subscribe
    // 3. onNext
    // 4. onCompleted / onError
    // 5. Disposed
    
    // 1. 비동기로 생기는 데이터를 Observable로 감싸서 리턴하는 방법
    // 기존의 RxSwift의 Observable을 사용
    func downloadJson(_ url: String) -> Observable<String> { // Observable<String?> 나중에 생기는 데이터
        // 0-1. 만약에 데이터 하나만 보낼경우
//        return Observable.just("Hello World")
        // 1-1. 직접 만들어보기
//        return Observable.create() { emitter in // 클로저가 들어간다.
//            emitter.onNext("Hello") // 데이터 전달 시에 'onNext' 사용
//            emitter.onNext("World") // 여러개 가능
//            emitter.onNext("Hello World")
//            emitter.onCompleted() // 데이터 전달이 완료되면? 'onCompleted'사용
//            
//            return Disposables.create() // Observable를 생성된 후 해당되는 코드에서 구독을 취소할 때, 리소스 누수를 방지. *Disposables: 리소스 정리 및 해제를 위한 도구
//        }
        // 1-2. URLSession 사용
        return Observable.create() { emitter in // 클로저가 들어간다.
            let url = URL(string: url)!
            let task = URLSession.shared.dataTask(with: url) { (data, _, err) in
                guard err == nil else { // nil이 아닌 경우 아래 코드 실행
                    emitter.onError(err!) // error가 생겼다.
                    return
                }
                
                if let dat = data, let json = String(data: dat, encoding: .utf8) {
                    emitter.onNext(json)
                }
                
                emitter.onCompleted()
            }
            
            task.resume()
            
            return Disposables.create() { // Observable를 생성된 후 해당되는 코드에서 구독을 취소할 때, 리소스 누수를 방지. *Disposables: 리소스 정리 및 해제를 위한 도구
                task.cancel() // URLSession의 데이터 작업을 취소하는 메서드
            }
        }
        
//        return Observable.create { f in
//            DispatchQueue.global().async {
//                let url = URL(string: url)!
//                let data = try! Data(contentsOf: url)
//                let json = String(data: data, encoding: .utf8)
//                
//                DispatchQueue.main.async {
//                    f.onNext(json)
//                    f.onCompleted() // 아래 [weak self]로 순환참조를 해결하긴 했지만, 이 한 문장으로도 해결할 수 있다.
//                }
//            }
//            return Disposables.create()
//        }
    }
    
    // 직접만든 ObservableSelf를 사용
//    func downloadJson(_ url: String) -> ObservableSelf<String?> {
//        return ObservableSelf() { f in
//            DispatchQueue.global().async {
//                let url = URL(string: url)!
//                let data = try! Data(contentsOf: url)
//                let json = String(data: data, encoding: .utf8)
//                
//                DispatchQueue.main.async {
//                    f(json)
//                }
//            }
//        }
//    }
    
    // MARK: SYNC
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func onLoad() {
        editView.text = ""
        
        self.setVisibleWithAnimation(self.activityIndicator, true)
        
        // onLoad() 함수에 처음 설정되어있던 값
        //DispatchQueue.global().async {
        //    let json = self.downloadJson(MEMBER_LIST_URL)
        //
        //    // UI Thread에서 적용해야한다.
        //    DispatchQueue.main.async {
        //        self.editView.text = json
        //        self.setVisibleWithAnimation(self.activityIndicator, false)
        //    }
        //}
        
        // completion을 사용하여 클로저 형태로 결과 값을 받을 경우
        //        downloadJson(MEMBER_LIST_URL) { json in
        //            self.editView.text = json
        //            self.setVisibleWithAnimation(self.activityIndicator, false)
        //        }
        
        // MARK: 순환 참조 설명
        /*
         두개 이상의 객체가 서로를 참조하는 상황
         Swift에서는 강한 참조로 인한 순환 참조를 방지하기 위해 약한 참조(weak reference)나 비소유 참조(unowned reference)를 사용할 수 있습니다.
         코드에서 'self'를 사용하면 현재 객체(클래스 인스턴스)를 참조합니다. 클로저 내에서 'self'를 사용할 때에는 주의가 필요한데, 특히 클로저가 해당 객체를 강한 참조하면서 순환 참조가 발생할 수 있습니다.
         */
        
        // 2. Observable로 오는 데이터를 받아서 처리하는 방법
        // 2-1. 직접 만들어 보기
        let observable = downloadJson(MEMBER_LIST_URL)
        let helloObservable = Observable.just("Hello World")
        
        // 한줄로 subscribe를 처리할 수 있음.
        let disposable = Observable
            // operator에는 다양한 게 있다. https://reactivex.io/documentation/operators.html 참조
            // 구슬을 이용해서 설명하는게 마블 다이어그램
            // 가로 화살표는 Oservable
//            .map { json in json?.count ?? 0} // .count를 이용해서 정수형으로 바꿀 수 있다. -> operator
//            .filter { cnt in cnt > 0 } // 0보다 큰 것만 모으고 -> operator
//            .map { "\($0)" } // 다시 String으로 바꿀 수 있다. -> operator
            .zip(observable, helloObservable) { $1 + "\n" + $0 } // zip을 통해 두개의 observable를 합쳤다.
            .observeOn(MainScheduler.instance) // DispatchQueue.main.async {}로 감싸줘야하는 것을 없애줌. -> super : operator. 다음줄에서 영향을 줌.
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default)) // 위치에 상관없이 어디에서 시작할지를 정해줌.
            .subscribe(onNext: { json in
                self.editView.text = json
                self.setVisibleWithAnimation(self.activityIndicator, false) },
                                              onError: {err in print(err) },
                                              onCompleted: { print("onCompleted") })
        
//        let disposable = observable.subscribe { event in
//            switch event {
//            case .next(let json):
//                DispatchQueue.main.async {
//                    self.editView.text = json
//                    self.setVisibleWithAnimation(self.activityIndicator, false)
//                }
//                break
//            case .error(let err):
//                break
//            case .completed:
//                break
//            }
//        }
//        // 작업을 취소할 때 아래 코드 사용.
//        disposable.dispose()
        
//        // RxSwift를 사용할 경우
//        downloadJson(MEMBER_LIST_URL)
//            .debug() // 윗줄과 아랫줄 사이에 데이터가 어떻게 움직이는지 터미널로 확인할 수 있음.
//            .subscribe { [weak self] event in // subscribe 나중에 오면 호출하는 것. 그에 따라 오는 것은 event. event는 각각 3개의 전달하는 것이 옴.
//                switch event {
//                case .next(let json): // 데이터가 전달되는 것이면 호출
//                    /*
//                     .subscribe 클로저 내에서 self를 사용하고 있습니다.
//                     이 클로저가 Observable을 구독하면서 해당 객체(클래스 인스턴스)에 대한 강한 참조가 발생할 수 있습니다.
//                     만약 Observable이 오랜 시간 동안 살아있는 경우에는, 해당 Observable이 강한 참조를 유지하여 객체가 메모리에서 해제되지 않고 남아있게 됩니다.
//
//                     순환 참조를 방지하려면 클로저 내에서 self에 대한 강한 참조 대신에 [weak self]나 [unowned self]를 사용하여 약한 참조나 비소유 참조로 변경할 수 있습니다.
//                     약한 참조는 객체가 nil이 될 수 있는 경우에 사용되며, 비소유 참조는 객체가 nil이 될 수 없는 경우에 사용됩니다.
//                     */
//                    
//                    // 1-1.
////                    self?.editView.text = json
////                    self?.setVisibleWithAnimation(self?.activityIndicator, false)
//                    // 1-2. URLSession의 경우
//                    DispatchQueue.main.async {
//                        self?.editView.text = json
//                        self?.setVisibleWithAnimation(self?.activityIndicator, false)
//                    }
//                // completed와 error에서 클로저의 역할이 끝나면서 사라진다.
//                case .completed: // 데이터가 전부가 전달되고 끝이라면 호출
//                    break
//                case .error: // 에러
//                    break
//                }
//            }
        
        // *Observable이 재사용이 안되는 이유.
//        let ob = downloadJson(MEMBER_LIST_URL)
//        
//        let disp = ob.subscribe { [weak self] event in // subscribe 나중에 오면 호출하는 것. 그에 따라 오는 것은 event. event는 각각 3개의 전달하는 것이 옴.
//            switch event {
//            case let .next(json):
//                DispatchQueue.main.async {
//                    self?.editView.text = json
//                    self?.setVisibleWithAnimation(self?.activityIndicator, false)
//                }
//            case .completed:
//                break
//            case .error: // 에러
//                break
//            }
//        }
        
//        disp.dispose() // dispose를 시킨 후 위에서 만든 observable ob는 아무것도 할 수 없다. - 재사용이 불가능하다.
        // 새롭게 생성을 하는 경우에 새로운 Observable이 동작하는 것임.
//        let disp1 = ob.subscribe....
        
        // 직접만든 ObservableSelf를 사용
//        downloadJson(MEMBER_LIST_URL)
//            .subscribe { json in
//                self.editView.text = json
//                self.setVisibleWithAnimation(self.activityIndicator, false)
//            }
    }
}
