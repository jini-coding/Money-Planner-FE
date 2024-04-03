//
//  LoginViewModel.swift
//  Money-Planner
//
//  Created by p_kxn_g on 3/7/24.
//

import Foundation
import RxSwift
import RxMoya
import Moya
import UIKit

class LoginViewModel {
    let loginRepository = LoginRepository()
    let disposeBag = DisposeBag()
    
    func isLoginEnabled() -> Observable<Bool> {
        return loginRepository.connect()
            .map { response in
                return response.isSuccess
            }
            .catch { error -> Observable<Bool> in
                // 오류가 발생한 경우에 대한 처리를 수행합니다.
                print(error)
                return Observable.just(false) // 로그인 불가능으로 처리
            }
    }


    func refreshAccessTokenIfNeeded() {
        // 이미 저장된 리프레시 토큰이 있는 경우
        if let refreshToken = TokenManager.shared.refreshToken {
            print(refreshToken)
            // 리프레시 토큰을 사용하여 새로운 액세스 토큰을 가져오는 요청을 수행합니다.
            let refreshTokenRequest = RefreshTokenRequest(refreshToken: refreshToken)
            loginRepository.refreshToken(refreshToken: refreshTokenRequest)
                .subscribe(onNext: { response in
                    print(response)
                    // 새로운 액세스 토큰이 성공적으로 갱신된 경우
                    if response.isSuccess {
                        // 갱신된 액세스 토큰을 저장하거나, 필요한 처리를 수행합니다.
                        if let result = response.result {
                            let accessToken  = result.accessToken
                            let refreshToken = result.refreshToken
                            
                            TokenManager.shared.handleLoginSuccess(accessToken: accessToken, refreshToken: refreshToken) // 토큰 업데이트
                            // 홈 화면으로 이동합니다.
                            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                                sceneDelegate.moveToHome()
                            }
                        }

                    } else {
                        // 실패한 경우에 대한 처리를 수행합니다.
                        print("Failed to refresh access token: \(response.message)")
                        // 디코딩 에러에서 상태 코드를 확인하여 401 에러인 경우 로그인 화면으로 이동
                        DispatchQueue.main.async {
                            let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
                            sceneDelegate?.moveToLogin()
                        }
                        
                    }
                }, onError: { error in
                    // 오류가 발생한 경우에 대한 처리를 수행합니다.
                    print(error)
                    print("Error refreshing access token: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
                        sceneDelegate?.moveToLogin()
                    }
                })
                .disposed(by: disposeBag)
        }
    }

    
    

    // 토큰이 없는 경우 > 로그인 화면
    func login(socialType:LoginRequest.SocialType, idToken:String){
        print(socialType, idToken)
        //print("로그인 api 연결")
        let request = LoginRequest(socialType: socialType, idToken: idToken)
        loginRepository.login(request: request)
            .subscribe(onNext: { response in
                print(response)
                if response.isSuccess == true {
                    
                    if let result = response.result {
                        // 토큰 업데이트
                        TokenManager.shared.handleLoginSuccess(accessToken: result.tokenInfo.accessToken, refreshToken: result.tokenInfo.refreshToken)
                        print("토큰 업데이트 완료 ------------------------------------------------")
                        print("엑세스 토큰 : ", String(TokenManager.shared.accessToken ?? "nil"))
                        print("리프레쉬 토큰 : ",  String(TokenManager.shared.refreshToken ?? "nil"))
                        print("------------------------------------------------")

                        if result.newMember {
                            print("새로운 회원 : 온보딩 화면으로 이동")
                            // 온보딩 화면으로 이동 (임시로 홈화면으로 이동)
                            // 홈 화면으로 이동합니다.
                            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                                sceneDelegate.moveToHome()
                            }                        }else{
                            print("원래 있던 회원 : 홈 화면으로 이동")
                            // 홈 화면으로 이동
                            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                                sceneDelegate.moveToHome()
                            }
                        }
                    }

                    
                }
            }, onError: { error in
                // 오류가 발생한 경우에 대한 처리를 수행합니다.
                print(error)
                print("Error refreshing access token: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
    
}
