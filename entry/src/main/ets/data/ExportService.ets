// data/ExportService.ets
// 负责 JSON 导入导出的鸿蒙文件 IO 部分。纯逻辑复用 ExportPureBridge。

import { picker } from '@kit.CoreFileKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Meeting, ActionItem, ExportPayload } from './types';
import { buildExportPayload, parseExportPayload, mergeImport, ImportReport } from './ExportPureBridge';
import { EXPORT_FILE_PREFIX, FILE_TYPE_JSON } from '../common/Constants';

export { buildExportPayload, parseExportPayload, mergeImport } from './ExportPureBridge';
export type { ImportReport as ExportReport } from './ExportPureBridge';

function formatTimestamp(ts: number): string {
  const d = new Date(ts);
  const pad = (n: number) => n.toString().padStart(2, '0');
  return `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}-${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
}

export async function exportToJson(
  meetings: Meeting[],
  actionItems: ActionItem[]
): Promise<string> {
  const payload = buildExportPayload(meetings, actionItems);
  const fileName = `${EXPORT_FILE_PREFIX}${formatTimestamp(payload.exportedAt)}.${FILE_TYPE_JSON}`;
  const documentSaveOptions = new picker.DocumentSaveOptions();
  documentSaveOptions.newFileNames = [fileName];
  documentSaveOptions.fileSuffixChoices = [FILE_TYPE_JSON];
  const documentPicker = new picker.DocumentViewPicker();
  const documentPickerResult = await documentPicker.save(documentSaveOptions);
  if (!documentPickerResult || documentPickerResult.length === 0) {
    throw new Error('用户取消保存');
  }
  const uri = documentPickerResult[0];
  const file = fileIo.openSync(uri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
  fileIo.writeSync(file.fd, JSON.stringify(payload, null, 2));
  fileIo.closeSync(file.fd);
  return fileName;
}

export async function importFromJson(): Promise<ExportPayload> {
  const documentPicker = new picker.DocumentViewPicker();
  const documentSelectOptions = new picker.DocumentSelectOptions();
  documentSelectOptions.fileSuffixFilters = [`.${FILE_TYPE_JSON}`];
  const uris = await documentPicker.select(documentSelectOptions);
  if (!uris || uris.length === 0) {
    throw new Error('用户取消选择');
  }
  const file = fileIo.openSync(uris[0], fileIo.OpenMode.READ_ONLY);
  const stat = fileIo.statSync(file.fd);
  const buf = new ArrayBuffer(stat.size);
  fileIo.readSync(file.fd, buf);
  fileIo.closeSync(file.fd);
  const text = new TextDecoder().decode(buf);
  return parseExportPayload(text);
}
