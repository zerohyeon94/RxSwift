//
//  MenuListViewModel.swift
//  RxSwift+MVVM
//
//  Created by 조영현 on 1/24/24.
//  Copyright © 2024 iamchiwon. All rights reserved.
//

import Foundation
import RxSwift

class MenuListViewModel {
    
    //    var itemsCount: Int = 5
    // var totalPrice: Int = 10_000
    // var totalPrice: Observable<Int> = Observable.just(10_000)
    
    // Subject를 사용하게되면 옵저버블 외부에서 접근이 가능하다.
    // var totalPrice: PublishSubject<Int> = PublishSubject()
    
    //    lazy var menuObservable = Observable.just(menus)
    // 1. menu array를 주어지게되면 옵저버블이 동작함
    //    var menuObservable = PublishSubject<[Menu]>()// 외부에서도 접근이 가능하게 하기 위해
    
    var menuObservable = BehaviorSubject<[Menu]>(value: []) // init에서 초기값이 들어가야한다.
    
    lazy var itemsCount = menuObservable.map {
        $0.map {
            $0.count
        }.reduce(0, +)
    }
    lazy var totalPrice = menuObservable.map {
        $0.map {
            $0.price * $0.count
        }.reduce(0, +)
    }
    
    init() {
        var menus: [Menu] = [
            Menu(id: 0, name: "튀김1", price: 1000, count: 0),
            Menu(id: 1, name: "튀김2", price: 1000, count: 0),
            Menu(id: 2, name: "튀김3", price: 1000, count: 0),
            Menu(id: 3, name: "튀김4", price: 1000, count: 0),
            Menu(id: 4, name: "튀김5", price: 1000, count: 0),
        ]
        
        menuObservable.onNext(menus)
    }
    
    func clearAllItemSelections() {
        _ = menuObservable
            .map { menus in
                return menus.map { m in
                    Menu(id: m.id, name: m.name, price: m.price, count: 0)
                }
            }
            .take(1) // 한번만 수행한다.
            .subscribe(onNext: {
                self.menuObservable.onNext($0)
            })
    }
    
    func changeCount(item: Menu, increase: Int) {
        _ = menuObservable
            .map { menus in
                menus.map { m in
                    if m.id == item.id {
                        Menu(id: m.id, name: m.name, price: m.price, count: m.count + increase)
                    } else {
                        Menu(id: m.id, name: m.name, price: m.price, count: m.count)
                    }
                    
                }
            }
            .take(1) // 한번만 수행한다.
            .subscribe(onNext: {
                self.menuObservable.onNext($0)
            })
    }
}
