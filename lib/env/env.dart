import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'CLOUDINARY_CLOUD_NAME')
  static final String cloudinaryCloudName = _Env.cloudinaryCloudName;

  @EnviedField(varName: 'CLOUDINARY_UPLOAD_PRESET')
  static final String cloudinaryUploadPreset = _Env.cloudinaryUploadPreset;
}
