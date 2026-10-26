// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revoke_others_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RevokeOthersResult _$RevokeOthersResultFromJson(Map<String, dynamic> json) =>
    RevokeOthersResult(
      ended: (json['ended'] as num).toInt(),
      deviceKeysRemoved: (json['device_keys_removed'] as num).toInt(),
    );

Map<String, dynamic> _$RevokeOthersResultToJson(RevokeOthersResult instance) =>
    <String, dynamic>{
      'ended': instance.ended,
      'device_keys_removed': instance.deviceKeysRemoved,
    };
