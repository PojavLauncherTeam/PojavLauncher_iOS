#import "TrackedTextField.h"
#import "ios_uikit_bridge.h"
#import "utils.h"
#include "glfw_keycodes.h"

extern bool isUseStackQueueCall;

// There are private functions that we are unable to find public replacements
// (Both are found by placing breakpoints)
@interface UITextField(private)
- (NSRange)insertFilteredText:(NSString *)text;
- (id) replaceRangeWithTextWithoutClosingTyping:(UITextRange *)range replacementText:(NSString *)text;
@end

@interface TrackedTextField()
@property(nonatomic) int lastTextPos;
@property(nonatomic) CGFloat lastPointX;
@end

@implementation TrackedTextField

- (void)sendMultiBackspaces:(int)times {
    for (int i = 0; i < times; i++) {
        CallbackBridge_nativeSendKey(GLFW_KEY_BACKSPACE, 0, 1, 0);
        CallbackBridge_nativeSendKey(GLFW_KEY_BACKSPACE, 0, 0, 0);
    }
}

- (void)sendText:(NSString *)text {
    for (int i = 0; i < text.length; i++) {
        // Directly convert unichar to jchar since both are in UTF-16 encoding.
        jchar theChar = (jchar) [text characterAtIndex:i];
        if (isUseStackQueueCall) {
            CallbackBridge_nativeSendCharMods(theChar, 0);
        } else {
            CallbackBridge_nativeSendChar(theChar);
        }
    }
}

- (void)beginFloatingCursorAtPoint:(CGPoint)point {
    [super beginFloatingCursorAtPoint:point];
    self.lastPointX = point.x;
}

// Handle cursor movement in the empty space
- (void)updateFloatingCursorAtPoint:(CGPoint)point {
    [super updateFloatingCursorAtPoint:point];

    if (self.lastPointX == 0 || (self.lastTextPos > 0 && self.lastTextPos < self.text.length)) {
        // This is handled in -[TrackedTextField closestPositionToPoint:]
        return;
    }

    CGFloat diff = point.x - self.lastPointX;
    if (ABS(diff) < 8) {
        return;
    }
    self.lastPointX = point.x;

    int key = (diff > 0) ? GLFW_KEY_DPAD_RIGHT : GLFW_KEY_DPAD_LEFT;
    CallbackBridge_nativeSendKey(key, 0, 1, 0);
    CallbackBridge_nativeSendKey(key, 0, 0, 0);
}

- (void)endFloatingCursor {
    [super endFloatingCursor];
    self.lastPointX = 0;
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point {
    // Handle cursor movement between characters
    UITextPosition *position = [super closestPositionToPoint:point];
    int start = [self offsetFromPosition:self.beginningOfDocument toPosition:position];
    if (start - self.lastTextPos != 0) {
        int key = (start - self.lastTextPos > 0) ? GLFW_KEY_DPAD_RIGHT : GLFW_KEY_DPAD_LEFT;
        CallbackBridge_nativeSendKey(key, 0, 1, 0);
        CallbackBridge_nativeSendKey(key, 0, 0, 0);
    }
    self.lastTextPos = start;
    return position;
}

- (void)deleteBackward {
    if (self.text.length > 1) {
        // Keep the first character (a space)
        [super deleteBackward];
    } else {
        self.text = @" ";
    }
    self.lastTextPos = [super offsetFromPosition:self.beginningOfDocument toPosition:self.selectedTextRange.start];

    [self sendMultiBackspaces:1];
}

- (BOOL)hasText {
    self.lastTextPos = MAX(self.lastTextPos, 1);
    return YES;
}

// Old name: insertText
- (NSRange)insertFilteredText:(NSString *)text {
    int cursorPos = [super offsetFromPosition:self.beginningOfDocument toPosition:self.selectedTextRange.start];

    // This also makes sure that lastTextPos != cursorPos (text should never be empty)
    if (self.lastTextPos - cursorPos == text.length) {
        // Handle text markup by first deleting N amount of characters equal to the replaced text
        [self sendMultiBackspaces:text.length];
    }
    // What else is done by past-autocomplete (insert a space after autocompletion)
    // See -[TrackedTextField replaceRangeWithTextWithoutClosingTyping:replacementText:]

    self.lastTextPos = cursorPos + text.length;

    [self sendText:text];

    NSRange range = [super insertFilteredText:text];
    return range;
}

- (id)replaceRangeWithTextWithoutClosingTyping:(UITextRange *)range replacementText:(NSString *)text
{
    int length = [super offsetFromPosition:range.start toPosition:range.end];

    // Delete the range of needs for autocompletion
    [self sendMultiBackspaces:length];

    // Insert the autocompleted text
    [self sendText:text];

    return [super replaceRangeWithTextWithoutClosingTyping:range replacementText:text];
}

@end
