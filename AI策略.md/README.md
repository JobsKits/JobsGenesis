# AI策略

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

## 一、脚本策略

```
1、运行脚本的时候，一定要经过用户确认
	1.1、先打印自述，当前运行的这个脚本是做什么的
	1.2、等待用户回车确认之后，方可往下执行，否则一直等待
	
2、一些现成的脚本片段代码参考：
https://github.com/JobsKits/JobsDocs/blob/main/🔥Shell脚本代码片段.md/Shell脚本代码片段.md

3、最后在main函数里面进行收口，main "$@"
main函数里面同样要写好注释

4、每个方法都要写注释

5、为了更好的兼容性，用#!/bin/zsh

6、自检的定义：如果存在则升级、没有监测到已经安装则安装最新版本
```

## 二、代码策略

```swift
1、用代码块+懒加载的形式

2、用snapkit来做约束
	2.1、约束写进我自己封装的一个Api里面：byAddTo
	     举例：
      x.byAddTo(view) { [unowned self] make in
                  if view.jobs_hasVisibleTopBar() {
                      make.top.equalTo(self.gk_navigationBar.snp.bottom).offset(10)
                      make.left.right.bottom.equalToSuperview()
                  } else {
                      make.edges.equalToSuperview()
                  }
              }
	2.2、外层用xxx..byVisible(YES) 来调用唤醒

3、导航栏用我自己写的Api：
	3.1、简单配置（只关心标题）
	jobsSetupGKNav(title: "这里写标题")
	3.2、复杂配置（完整配置）
  jobsSetupGKNav(
      title: "Demo 列表",
      leftButton:UIButton.sys()
          .byFrame(CGRect(x: 0, y: 0, width: 32.w, height: 32.h))
          /// 按钮图片@图文关系
          .byImage("list.bullet".sysImg, for: .normal)
          .byImage("list.bullet".sysImg, for: .selected)
          /// 普通@点按事件触发
          .onTap {[weak self] sender in
              guard let self else { return }
              sender.isSelected.toggle()
              self.jobsSideDrawer?.toggleDrawer()
//                    let cell = tableView[section: 0, row: 3]
//                    let cell1 = tableView[section: 12, row: 3]
              print("")
          }
          /// 追加@点按事件触发
          .onTapAppend{ sender in
              print("追加的点按事件")
          }
          /// 普通@长按事件触发
          .onLongPress(minimumPressDuration: 0.8) { btn, gr in
               if gr.state == .began {
                   btn.alpha = 0.6
                   print("长按开始 on \(btn)")
               } else if gr.state == .ended || gr.state == .cancelled {
                   btn.alpha = 1.0
                   print("长按结束")
               }
          }
          /// 追加@长按事件触发
          .onLongPressAppend(minimumPressDuration: 0.8) { btn, gr in
              print("追加的长按事件")
          },
      rightButtons: [
          UIButton.sys()
              /// 按钮图片@图文关系
              .byImage("moon.circle.fill".sysImg, for: .normal)
              .byImage("moon.circle.fill".sysImg, for: .selected)
              /// 事件触发@点按
              .onTap { sender in
                  sender.isSelected.toggle()
                  guard let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                        let win = ws.windows.first else { return }
                  win.overrideUserInterfaceStyle =
                      (win.overrideUserInterfaceStyle == .dark) ? .light : .dark
                  print("🌓 主题已切换 -> \(win.overrideUserInterfaceStyle == .dark ? "Dark" : "Light")")
              },
          UIButton.sys()
              /// 按钮图片@图文关系
              .byImage("globe".sysImg, for: .normal)
              .byImage("globe".sysImg, for: .selected)
              /// 事件触发@点按
              .onTap { [weak self] sender in
                  guard let self else { return }
                  sender.isSelected.toggle()
                  let to = (LanguageManager.shared.currentLanguageCode == "zh-Hans") ? "en" : "zh-Hans"
                  LanguageManager.shared.switchTo(to)
//                        var s = "🔑 注册登录".tr
                  tableView.reloadData()
                  print("🌐 切换语言 tapped（占位）")
              },
          UIButton.sys()
              /// 按钮图片@图文关系
              .byImage("stop.circle.fill".sysImg, for: .normal)
              .byImage("stop.circle.fill".sysImg, for: .selected)
              /// 事件触发@点按
              .onTap { [weak self] sender in
                  guard let self else { return }
                  sender.isSelected.toggle()
                  print("🛑 手动停止刷新")
                  isPullRefreshing = false
                  isLoadingMore    = false
              }
      ]
  )
  
4、控制器统一继承于 BaseVC 

5、最顶上的系统基础框架
#if os(OSX)
import AppKit
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

6、我自己封装的，并且本地pod化的框架，需要引入
import JobsByUIKit

import JobsSwiftBlock
```



