//
//  ViewController.swift
//  pomodoro
//
//  Created by 구희정 on 2022/03/08.
//

import UIKit
import AudioToolbox

enum TimerStatus {
    case start
    case pause
    case end
}

class ViewController: UIViewController {
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var progresView: UIProgressView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var toggleButton: UIButton!
    
    @IBOutlet weak var imageView: UIImageView!
    //타이머에 설정된 시간을 초로 저장함.
    //60으로 초기화 하는 이유 기본적으로 datePicker값이 1분으로 되어이있기 때문
    var duration = 60
    
    //타이머의 상태를 갖고 있는 프로퍼티
    var timerStatus: TimerStatus = .end
    
    //GCD 관련 DispatchSourceTimer
    var timer : DispatchSourceTimer?
    
    //현재 카운트 다운이 되고 있는 시간을 저장하는 프로퍼티
    var currentSeconds = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureToggleButton()
        
    }
    //취소 버튼
    @IBAction func TapCancelButton(_ sender: UIButton) {
        switch self.timerStatus {
        case .start,.pause:
            self.stopTimer()
            
        default:
            break
            
        }
    }
    //시작 및 일시정지 버튼
    @IBAction func TapToggleButton(_ sender: UIButton) {
        //countDownDuration 은 '초' 로 가져온다.
        self.duration = Int(self.datePicker.countDownDuration)
        
        switch self.timerStatus {
        case .end:
            self.timerStatus = .start
            
            //isHidden 을 사용하게 되면 화면이 뚝뚝 끊기는 현상이 있기 때문에
            //부드럽고 자연스럽게 화면에서 사라지는 애니메이션을 만든다.
            //withDuration 은 애니메이션이 얼마만큼 지속되는지
            //alpha 값은 0 ~ 1 까지 있으며, 투명도를 뜻한다.
            UIView.animate(withDuration: 0.5, animations: {
                self.timerLabel.alpha = 1
                self.progresView.alpha = 1
                self.datePicker.alpha = 0
            })
            self.toggleButton.isSelected = true
            self.cancelButton.isEnabled = true
            self.currentSeconds = self.duration
            self.startTimer()
            
        case .start:
            self.timerStatus = .pause
            self.toggleButton.isSelected = false
            self.timer?.suspend()
            
        case .pause:
            self.timerStatus = .start
            self.toggleButton.isSelected = true
            self.timer?.resume()
            
        }
    }
    
    func setTimerInfoViewVisible(isHidden: Bool){
        self.timerLabel.isHidden = isHidden
        self.progresView.isHidden = isHidden
        
    }
    
    func configureToggleButton() {
        //버튼의 상태에 따라 '시작','일시정지' 값을 지정 할 수 있다.
        self.toggleButton.setTitle("시작", for: .normal)
        self.toggleButton.setTitle("일시정지", for: .selected)
    }
    
    func startTimer() {
        if self.timer == nil {
            //UI 와 관련된 작업은 반드시 main스레드에서 작업을 해야한다.
            self.timer = DispatchSource.makeTimerSource(flags: [], queue: .main)
            //어떤 주기로 timer를 실행 할 것인지.
            //.now()는 바로 시작 하겠다.
            //repeating - 몇 초마다 반복을 할 것이냐.
            self.timer?.schedule(deadline: .now(), repeating: 1)
            //timer와 함께 연동된 이번트 핸들러
            //타이머가 동작 될 때마다 이벤트 핸들러가 호출이 된다.
            //즉 위에서 1초마다 한번씩 아래 이벤트 핸들러 호출
            self.timer?.setEventHandler(handler: { [weak self] in guard let self = self else { return }
                self.currentSeconds -= 1
                let hour = self.currentSeconds / 3600
                let minutes = (self.currentSeconds % 3600 ) / 60
                let second = (self.currentSeconds % 3600 ) % 60
                self.timerLabel.text = String(format: "%02d:%02d:%02d", hour,minutes,second)
                //progress는 0 ~ 1 까지의 수로 이뤄져 있기 때문에 아래와 같이 Float타입을 사용한다.
                //현재 카운트 다운 되고 있는 시간 / 설정한 값
                self.progresView.progress = Float(self.currentSeconds) / Float(self.duration)
                
                //이미지 뷰를
                UIView.animate(withDuration: 0.5, delay: 0 , animations: {
                    self.imageView.transform = CGAffineTransform(rotationAngle: .pi)
                })
                UIView.animate(withDuration: 0.5, delay: 0.5 ,animations: {
                    self.imageView.transform = CGAffineTransform(rotationAngle: .pi * 2)
                })
                
                //타이머가 완료 되었을 때
                //currentSeconds = 0
                if self.currentSeconds <= 0 {
                    self.stopTimer()
                    //SystemSoundId 값은 아래 링크에서 확인 가능하다.
                    //https://iphonedev.wiki/index.php/AudioServices
                    
                    AudioServicesPlaySystemSound(1005)
                }
            })
            self.timer?.resume()
        }
    }
    func stopTimer() {
        //취소 버튼을 눌렀을 경우 timer를 resume 상태로 바꿔 주고, nil을 할당해야한다.
        if self.timerStatus == .pause {
            self.timer?.resume()
        }
        //타이머를 꼭 nil 을 할당 시켜서 메모리에서 해제를 시켜줘야 한다.
        //그렇지 않으면 화면을 벗어나도 계속 타이머가 동작 할 수 있다.
        self.timer?.cancel()
        self.timer = nil
        
        self.timerStatus = .end
        self.cancelButton.isEnabled = false
        self.toggleButton.isSelected = false
        UIView.animate(withDuration: 0.5, animations: {
            self.timerLabel.alpha = 0
            self.progresView.alpha = 0
            self.datePicker.alpha = 1
            self.imageView.transform = .identity
        })
    }
}

