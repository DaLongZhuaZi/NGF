import { media } from '@kit.MediaKit';
import { logger } from '../../utils/Logger';

const TAG: string = 'NGFAVPlayer';

@Component
export struct NGFAVPlayer {
  @Prop videoUrl: string;
  @State private isPlaying: boolean = false;
  
  // 原生 Video 组件支持直接传入 url 播放
  private controller: VideoController = new VideoController();

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Video({
        src: this.videoUrl,
        controller: this.controller
      })
      .width('100%')
      .height('100%')
      .autoPlay(false)
      .controls(true)
      .onStart(() => {
        logger.info(TAG, '视频开始播放');
        this.isPlaying = true;
      })
      .onPause(() => {
        logger.info(TAG, '视频暂停');
        this.isPlaying = false;
      })
      .onFinish(() => {
        logger.info(TAG, '视频播放完成');
        this.isPlaying = false;
      })
      .onError(() => {
        logger.error(TAG, '视频播放出错');
      })
    }
    .width('100%')
    .height(200)
    .backgroundColor('#000000')
  }
}
