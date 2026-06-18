import 'package:flutter/material.dart';

import '../../theme/dinq_tokens.dart';
import '../../widgets/common/default_app_bar.dart';
import '../mydinq/mydinq_resume_content.dart';

/// My → Resume 简历管理。
class ResumePage extends StatelessWidget {
  const ResumePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(context, titleString: 'Resume'),
      body: const MyDinqResumeContent(),
    );
  }
}
