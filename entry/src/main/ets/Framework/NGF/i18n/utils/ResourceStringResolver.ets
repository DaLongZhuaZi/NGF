/**
 * Resolve a Resource reference to its localized string value synchronously.
 * If the input is already a string, it is returned as-is.
 * Returns empty string when context or resourceManager is unavailable, or when resolution fails.
 *
 * Usage:
 *   const text: string = resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.my_key'));
 */
export function resolveResourceString(context: Context | undefined, res: ResourceStr): string {
  if (typeof res === 'string') {
    return res;
  }
  if (!context || !context.resourceManager) {
    return '';
  }
  try {
    return context.resourceManager.getStringSync(res.id);
  } catch (e) {
    return '';
  }
}
