#import <Foundation/Foundation.h>

enum{
    NSStringScoreOptionNone                         = 1 << 0,
    NSStringScoreOptionFavorSmallerWords            = 1 << 1,
    NSStringScoreOptionReducedLongStringPenalty     = 1 << 2
};

typedef NSUInteger NSStringScoreOption;

@interface NSString (Score)

- (float)scoreAgainst:(NSString *)otherString;
- (float)scoreAgainst:(NSString *)otherString fuzziness:(NSNumber *)fuzziness;
- (float)scoreAgainst:(NSString *)otherString fuzziness:(NSNumber *)fuzziness options:(NSStringScoreOption)options;

@end
