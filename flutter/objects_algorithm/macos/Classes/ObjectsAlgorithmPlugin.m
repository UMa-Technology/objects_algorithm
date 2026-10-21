#import "ObjectsAlgorithmPlugin.h"

// Defined in Classes/generated/objects_algorithm_keepalive.cpp.
extern const void *objects_algorithm_keepalive_anchor(void);

// See ios/Classes/ObjectsAlgorithmPlugin.m for details.
@implementation ObjectsAlgorithmPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  static const void *volatile keepalive;
  keepalive = objects_algorithm_keepalive_anchor();
  (void)keepalive;
}

@end
