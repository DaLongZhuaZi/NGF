export interface IMediaPicker {
  /**
   * 调起系统安全的图片选择器 (PhotoPicker)
   * @param maxSelectNumber 最大选择数量
   * @returns 选中图片的 URI 数组
   */
  pickImages(maxSelectNumber: number): Promise<Array<string>>;

  /**
   * 调起系统安全的视频选择器
   * @param maxSelectNumber 最大选择数量
   * @returns 选中视频的 URI 数组
   */
  pickVideos(maxSelectNumber: number): Promise<Array<string>>;
}
