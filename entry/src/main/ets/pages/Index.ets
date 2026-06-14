// pages/Index.ets
// 启动页：立即跳转到 HomePage

import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  aboutToAppear(): void {
    setTimeout(() => {
      router.replaceUrl({ url: 'pages/HomePage' });
    }, 0);
  }

  build() {
    Column() {
      Text('会议 PDCA')
        .fontSize(20)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
