//
//  SZTextView.m
//  SZTextView
//
//  Created by glaszig on 14.03.13.
//  Copyright (c) 2013 glaszig. All rights reserved.
//

#import "SZTextView.h"

#define HAS_TEXT_CONTAINER [self respondsToSelector:@selector(textContainer)]
#define HAS_TEXT_CONTAINER_INSETS(x) [(x) respondsToSelector:@selector(textContainerInset)]
#define Y_PADDING (HAS_TEXT_CONTAINER_INSETS(self) ? 0.0f : kUITextViewPadding)
#define X_PADDING (HAS_TEXT_CONTAINER_INSETS(self) ? 4.0f : kUITextViewPadding)

@interface SZTextView ()
@property (strong, nonatomic) UITextView *_placeholderLabel DEPRECATED_ATTRIBUTE;
@property (strong, nonatomic) UITextView *_placeholderTextView;
@end

static NSString *kPlaceholderKey = @"placeholder";
static NSString *kFontKey = @"font";
static NSString *kTextKey = @"text";
static NSString *kExclusionPaths = @"exclusionPaths";
static float kUITextViewPadding = 8.0;

@implementation SZTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self awakeFromNib];
    }
    return self;
}

- (void)awakeFromNib
{
    // the label which displays the placeholder
    // needs to inherit some properties from its parent text view

    // account for standard UITextViewPadding
    
    CGRect frame = CGRectMake(X_PADDING, Y_PADDING, 0, 0);
    self._placeholderTextView = [[UITextView alloc] initWithFrame:frame];
    self._placeholderTextView.opaque = NO;
    self._placeholderTextView.backgroundColor = [UIColor clearColor];
    self._placeholderTextView.textColor = [UIColor grayColor];
    self._placeholderTextView.textAlignment = self.textAlignment;
    self._placeholderTextView.textContainerInset = UIEdgeInsetsZero;
    self._placeholderTextView.editable = NO;
    self._placeholderTextView.selectable = NO;
    self._placeholderTextView.scrollEnabled = NO;
    self._placeholderTextView.userInteractionEnabled = NO;
    self._placeholderTextView.font = self.font;
    
    if (HAS_TEXT_CONTAINER) {
        self._placeholderTextView.textContainer.exclusionPaths = self.textContainer.exclusionPaths;
    }
    
    if (_placeholder) {
        self._placeholderTextView.text = _placeholder;
    }
    
    [self addSubview:self._placeholderTextView];
    self.clipsToBounds = YES;

    // some observations
    NSNotificationCenter *defaultCenter;
    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(textDidChange:)
                          name:UITextViewTextDidChangeNotification object:self];

    [self addObserver:self forKeyPath:kPlaceholderKey
              options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:kFontKey
              options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:kTextKey
              options:NSKeyValueObservingOptionNew context:nil];
    
    if (HAS_TEXT_CONTAINER) {
        [self.textContainer addObserver:self forKeyPath:kExclusionPaths
                                options:NSKeyValueObservingOptionNew context:nil];
    }

}

- (void)setPlaceholder:(NSString *)placeholderText
{
    _placeholder = placeholderText;
    [self resizePlaceholderFrame];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self resizePlaceholderFrame];
}

- (void)resizePlaceholderFrame
{
    UIEdgeInsets inset;
    
    if (HAS_TEXT_CONTAINER_INSETS(self)) {
        inset = self.textContainerInset;
    }
    else {
        inset = self.contentInset;
    }
    
    CGRect frame = self._placeholderTextView.frame;
    
    // the width needs to be limited to the text view's width
    // to prevent the label text from bleeding off
    frame.size.width = self.bounds.size.width;
    frame.size.width -= 2 * X_PADDING + inset.right + inset.left;

    CGSize labelSize = [_placeholder sizeWithFont:self._placeholderTextView.font
                                constrainedToSize:CGSizeMake(frame.size.width, 1000)
                                    lineBreakMode:NSLineBreakByWordWrapping];
    
    if (HAS_TEXT_CONTAINER) {
        NSLayoutManager * layoutManager = self._placeholderTextView.layoutManager;
        [layoutManager glyphRangeForTextContainer:self._placeholderTextView.textContainer];
        CGFloat height = [layoutManager usedRectForTextContainer:self._placeholderTextView.textContainer].size.height;
        
        labelSize.height = height;
    }
    
    
    frame.size.height = labelSize.height;
    
    if (HAS_TEXT_CONTAINER_INSETS(self)) {
        frame.origin.y = Y_PADDING + inset.top;
        frame.origin.x = X_PADDING + inset.left;
    }
    
    self._placeholderTextView.frame = frame;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kPlaceholderKey]) {
        self._placeholderTextView.text = [change valueForKey:NSKeyValueChangeNewKey];
        [self._placeholderTextView sizeToFit];
    }
    else if ([keyPath isEqualToString:kFontKey]) {
        self._placeholderTextView.font = [change valueForKey:NSKeyValueChangeNewKey];
        [self._placeholderTextView sizeToFit];
    }
    else if ([keyPath isEqualToString:kTextKey]) {
        NSString *newText = [change valueForKey:NSKeyValueChangeNewKey];
        if (newText.length > 0) {
            [self._placeholderTextView removeFromSuperview];
        } else {
            [self addSubview:self._placeholderTextView];
        }
    } else if ([keyPath isEqualToString:kExclusionPaths]) {
        self._placeholderTextView.textContainer.exclusionPaths = [change objectForKey:NSKeyValueChangeNewKey];
        [self resizePlaceholderFrame];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setPlaceholderTextColor:(UIColor *)placeholderTextColor
{
    self._placeholderTextView.textColor = placeholderTextColor;
}

- (UIColor *)placeholderTextColor
{
    return self._placeholderTextView.textColor;
}

- (void)textDidChange:(NSNotification *)aNotification
{
    if (self.text.length < 1) {
        [self addSubview:self._placeholderTextView];
        [self sendSubviewToBack:self._placeholderTextView];
    } else {
        [self._placeholderTextView removeFromSuperview];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:kPlaceholderKey];
    [self removeObserver:self forKeyPath:kFontKey];
    [self removeObserver:self forKeyPath:kTextKey];

    if (HAS_TEXT_CONTAINER) {
        [self.textContainer removeObserver:self forKeyPath:kExclusionPaths];
    }
}

#pragma mark - Deprecations

- (void)set_placeholderLabel:(UITextView *)placeholderLabel
{
    NSLog(@"[SZTextView _placeholderLabel] is deprecated and will disappear in the next release of SZTextView.");
    __placeholderTextView = placeholderLabel;
}

- (UITextView *)_placeholderLabel
{
    NSLog(@"[SZTextView _placeholderLabel] is deprecated and will disappear in the next release of SZTextView.");
    return __placeholderTextView;
}

@end

