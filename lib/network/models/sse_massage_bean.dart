enum AiWriteSseMassageEvent { error, streamId, content, done, sensitive }

extension AiWriteSseMassageEventEx on AiWriteSseMassageEvent {
  static AiWriteSseMassageEvent init(String value) {
    if (value == "error") {
      return AiWriteSseMassageEvent.error;
    } else if (value == "sensitive") {
      return AiWriteSseMassageEvent.sensitive;
    } else if (value == "stream_id") {
      return AiWriteSseMassageEvent.streamId;
    } else if (value == "content") {
      return AiWriteSseMassageEvent.content;
    } else if (value == "done") {
      return AiWriteSseMassageEvent.done;
    }
    return AiWriteSseMassageEvent.error;
  }
}

class AiWriteSseMassageBean {
  AiWriteSseMassageEvent? event;
  Map<String, dynamic>? data;

  AiWriteSseMassageBean(String eventStr, {Map<String, dynamic>? json}) {
    event = AiWriteSseMassageEventEx.init(eventStr);
    if (json != null) {
      data = json;
    }
  }
}

class SseMassageBean {
  String? event;
  Map<String, dynamic>? data;

  SseMassageBean(String eventStr, {Map<String, dynamic>? json}) {
    event = eventStr;
    if (json != null) {
      data = json;
    }
  }
}
