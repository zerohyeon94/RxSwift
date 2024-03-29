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
        // 데이터를 넣는 부분
        _ = APIService.fetchAllMenusRx()
            .map { data -> [MenuItem] in
                struct Response: Decodable {
                    let menus: [MenuItem]
                }
                
                let response = try! JSONDecoder().decode(Response.self, from: data)
                
                return response.menus
            }
            .map { menuItems -> [Menu] in
                var menus: [Menu] = []
                menuItems.enumerated().forEach { (index, item) in
                    let menu = Menu.fromMenuItems(id: index, item: item)
                    menus.append(menu)
                }
                return menus
            }
            .take(1)
            .bind(to: menuObservable)
    }
    
    func onOrder() {
        
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
                        return Menu(id: m.id, name: m.name, price: m.price, count: max(m.count + increase, 0))
                    } else {
                        return Menu(id: m.id, name: m.name, price: m.price, count: m.count)
                    }
                    
                }
            }
            .take(1) // 한번만 수행한다.
            .subscribe(onNext: {
                self.menuObservable.onNext($0)
            })
    }
}
