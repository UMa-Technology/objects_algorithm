#import "ObjectsAlgorithmPlugin.h"

// Defined in Classes/generated/objects_algorithm_keepalive.cpp.
extern const void *objects_algorithm_keepalive_anchor(void);

// This class exists solely to pin the KPCAA* symbols in the final binary.
//
// Chain: the host's GeneratedPluginRegistrant.m references [ObjectsAlgorithmPlugin class]
//   -> pulls in this translation unit
//   -> this unit's undefined reference to objects_algorithm_keepalive_anchor pulls in the keepalive unit
//   -> the keepalive unit takes the address of every KPCAA* function, pulling in the aainterface units
//   -> the aainterface implementations reference aaplus, which survives transitively
//
// Without this starting point the whole chain is a set of archive members that reference each
// other but are referenced by nothing; the linker discards them wholesale before dead-stripping
// even runs, and __attribute__((used)) can't save them.
@implementation ObjectsAlgorithmPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  static const void *volatile keepalive;
  keepalive = objects_algorithm_keepalive_anchor();
  (void)keepalive;
}

@end
