import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/json_values.dart';

void main() {
  group('jsonString', () {
    test('字符串原样返回', () => expect(jsonString('abc'), 'abc'));
    test('null 用兜底值', () {
      expect(jsonString(null), '');
      expect(jsonString(null, 'x'), 'x');
    });
    test('数值/布尔按 toString 降级', () {
      expect(jsonString(1), '1');
      expect(jsonString(true), 'true');
    });
  });

  group('jsonStringOrNull', () {
    test('null 保持 null', () => expect(jsonStringOrNull(null), isNull));
    test('数值降级为字符串', () => expect(jsonStringOrNull(7), '7'));
  });

  group('jsonInt', () {
    test('数字类型直接转换', () {
      expect(jsonInt(3), 3);
      expect(jsonInt(3.9), 3);
    });
    test('数字字符串可解析（LLM 常见类型漂移）', () {
      expect(jsonInt('12'), 12);
      expect(jsonInt(' 42 '), 42);
    });
    test('不可解析时用兜底值', () {
      expect(jsonInt('abc'), 0);
      expect(jsonInt('abc', 7), 7);
      expect(jsonInt(null), 0);
      expect(jsonInt({}), 0);
    });
  });

  group('jsonBool', () {
    test('布尔原样返回', () {
      expect(jsonBool(true), true);
      expect(jsonBool(false), false);
    });
    test('字符串形式识别', () {
      expect(jsonBool('true'), true);
      expect(jsonBool('TRUE'), true);
      expect(jsonBool('yes'), true);
      expect(jsonBool('1'), true);
      expect(jsonBool('false'), false);
      expect(jsonBool('no'), false);
      expect(jsonBool('0'), false);
    });
    test('非零数值视为 true', () => expect(jsonBool(1), true));
    test('无法识别时用兜底值', () {
      expect(jsonBool('可能'), false);
      expect(jsonBool('可能', true), true);
      expect(jsonBool(null), false);
    });
  });

  group('jsonList / jsonMap', () {
    test('类型不符时返回空集合', () {
      expect(jsonList(null), isEmpty);
      expect(jsonList('x'), isEmpty);
      expect(jsonList({'a': 1}), isEmpty);
      expect(jsonMap(null), isEmpty);
      expect(jsonMap([1, 2]), isEmpty);
    });
    test('数组保留元素', () => expect(jsonList([1, 'a']).length, 2));
    test('Map 统一为 String 键', () {
      final m = jsonMap(<dynamic, dynamic>{'k': 1});
      expect(m['k'], 1);
    });
  });

  group('extractJsonObject', () {
    test('纯 JSON 对象', () {
      expect(extractJsonObject('{"a":1}'), {'a': 1});
    });
    test('markdown 代码块包裹', () {
      expect(extractJsonObject('```json\n{"a":1}\n```'), {'a': 1});
      expect(extractJsonObject('```\n{"a":1}\n```'), {'a': 1});
    });
    test('JSON 前后带解释文字', () {
      expect(extractJsonObject('好的，结果如下：\n{"a":1}\n以上。'), {'a': 1});
    });
    test('代码块后带解释文字', () {
      expect(extractJsonObject('```json\n{"a":1}\n```\n说明：略'), {'a': 1});
    });
    test('LLM 把数字写成字符串仍可解析', () {
      expect(extractJsonObject('{"seq":"1","name":"A"}'), {
        'seq': '1',
        'name': 'A',
      });
    });
    test('纯文字回复抛异常（不吞成空结果）', () {
      expect(() => extractJsonObject('抱歉，我无法完成该任务。'), throwsFormatException);
    });
    test('畸形 JSON 抛异常', () {
      expect(() => extractJsonObject('{"a":1,}'), throwsFormatException);
    });
    test('顶层是数组抛异常（避免上层误当空结果落库）', () {
      expect(() => extractJsonObject('[1,2,3]'), throwsFormatException);
    });
    test('空字符串抛异常', () {
      expect(() => extractJsonObject(''), throwsFormatException);
    });
  });
}
