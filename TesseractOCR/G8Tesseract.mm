//
//  G8Tesseract.mm
//  Tesseract OCR iOS
//
//  Created by Loïs Di Qual on 24/09/12.
//  Copyright (c) 2012 Loïs Di Qual.
//  Under MIT License. See 'LICENCE' for more informations.
//

#import "G8Tesseract.h"

#import "G8PixWrapper.h"
#import "G8TextMonitor.h"
#import "UIImage+G8Filters.h"
#import "G8TesseractParameters.h"
#import "G8Constants.h"
#import "G8RecognizedBlock.h"
#import "G8HierarchicalRecognizedBlock.h"

#import <Leptonica/allheaders.h>
#import <Leptonica/alltypes.h>

#import <Tesseract/baseapi.h>
#import <Tesseract/ocrclass.h>
#import <Tesseract/renderer.h>

#include <string>
#include <vector>
#include <memory>
#include <stdexcept>

NSInteger const kG8DefaultResolution = 72;
NSInteger const kG8MinCredibleResolution = 70;
NSInteger const kG8MaxCredibleResolution = 2400;

// Forward declare the callback function used by TextMonitor
static bool tesseractCancelCallbackFunction(void *cancel_this, int words);

/**
 * Private interface extension for G8Tesseract
 */
@interface G8Tesseract () {
    std::unique_ptr<tesseract::TessBaseAPI> _tesseract;
    std::unique_ptr<g8::TextMonitor> _monitor;
}

@property (nonatomic, strong) NSDictionary *configDictionary;
@property (nonatomic, strong) NSArray *configFileNames;
@property (nonatomic, strong) NSMutableDictionary *variables;

@property (readwrite, assign) CGSize imageSize;

@property (nonatomic, assign, getter=isRecognized) BOOL recognized;
@property (nonatomic, assign, getter=isLayoutAnalysed) BOOL layoutAnalysed;

@property (nonatomic, assign) G8Orientation orientation;
@property (nonatomic, assign) G8WritingDirection writingDirection;
@property (nonatomic, assign) G8TextlineOrder textlineOrder;
@property (nonatomic, assign) CGFloat deskewAngle;

@end

@implementation G8Tesseract

+ (void)initialize {
    if (self == [G8Tesseract self]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarningNotification:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
}

+ (void)didReceiveMemoryWarningNotification:(NSNotification*)notification {
    [self clearCache];
}

+ (NSString *)version {
    return [NSString stringWithUTF8String:tesseract::TessBaseAPI::Version()];
}

+ (void)clearCache {
    tesseract::TessBaseAPI::ClearPersistentCache();
}

- (instancetype)init {
    return [self initWithLanguage:nil
                 configDictionary:nil
                  configFileNames:nil
                 absoluteDataPath:nil
                       engineMode:G8OCREngineModeDefault];
}

- (instancetype)initWithLanguage:(NSString*)language {
    return [self initWithLanguage:language engineMode:G8OCREngineModeDefault];
}

- (instancetype)initWithLanguage:(NSString *)language engineMode:(G8OCREngineMode)engineMode {
    return [self initWithLanguage:language
                 configDictionary:nil
                  configFileNames:nil
                 absoluteDataPath:nil
                       engineMode:engineMode];
}

- (instancetype)initWithLanguage:(NSString *)language
                configDictionary:(NSDictionary *)configDictionary
                 configFileNames:(NSArray *)configFileNames
           cachesRelatedDataPath:(NSString *)cachesRelatedDataPath
                      engineMode:(G8OCREngineMode)engineMode {
    NSArray *cachesPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesPath = cachesPaths.firstObject;
    NSString *absoluteDataPath = cachesRelatedDataPath ? [cachesPath stringByAppendingPathComponent:cachesRelatedDataPath] : nil;

    return [self initWithLanguage:language
                 configDictionary:configDictionary
                  configFileNames:configFileNames
                 absoluteDataPath:absoluteDataPath
                       engineMode:engineMode];
}


- (instancetype)initWithLanguage:(NSString *)language
                configDictionary:(NSDictionary *)configDictionary
                 configFileNames:(NSArray *)configFileNames
                absoluteDataPath:(NSString *)absoluteDataPath
                      engineMode:(G8OCREngineMode)engineMode {
    self = [super init];
    if (self) {
        // Basic setup
        _pageSegmentationMode = G8PageSegmentationModeSingleBlock;
        _variables = [NSMutableDictionary dictionary];
        _sourceResolution = kG8DefaultResolution;
        _rect = CGRectZero;

        // Monitor setup
        try {
            _monitor = std::make_unique<g8::TextMonitor>(
                                                         tesseractCancelCallbackFunction,
                                                         (__bridge void*)self
                                                         );
        } catch (const std::bad_alloc&) {
            return nil;
        }

        // Language and engine mode
        _language = language.copy;
        _engineMode = engineMode;

        // Path setup and validation
        BOOL shouldConfigureEngine = YES;
        if (absoluteDataPath) {
            if ([self moveTessdataToDirectoryIfNecessary:absoluteDataPath]) {
                _absoluteDataPath = absoluteDataPath.copy;
            } else {
                shouldConfigureEngine = NO;
                _absoluteDataPath = absoluteDataPath.copy;  // Still set it even if move fails
            }
        } else {
            _absoluteDataPath = [NSBundle mainBundle].bundlePath;
        }

        // Set environment variable regardless of move success
        if (_absoluteDataPath) {
            _absoluteDataPath = [_absoluteDataPath stringByAppendingString:@"/tessdata/"];
            setenv("TESSDATA_PREFIX", _absoluteDataPath.fileSystemRepresentation, 1);
        }

        // Config setup
        if (configDictionary) {
            _configDictionary = configDictionary;
        }
        if (configFileNames) {
            _configFileNames = configFileNames;
        }

        // Initialize engine only if everything is valid
        if (shouldConfigureEngine) {
            [self configEngine];
        }
    }
    return self;
}

/**
 * Configures the Tesseract engine with current settings
 * @return YES if configuration was successful, NO otherwise
 */
- (BOOL)configEngine {
    try {
        std::vector<std::string> vars_vec;
        std::vector<std::string> vars_values;

        // Fill vectors if we have config dictionary
        if (self.configDictionary) {
            [self fillVectors:vars_vec values:vars_values fromDictionary:self.configDictionary];
        }

        // Handle config files
        std::vector<std::unique_ptr<char[]>> configPtrs;
        std::vector<char*> configs;

        if (self.configFileNames) {
            configPtrs.reserve(self.configFileNames.count);
            configs.reserve(self.configFileNames.count);

            for (NSString *configFile in self.configFileNames) {
                const char *utf8String = [configFile UTF8String];
                auto ptr = std::make_unique<char[]>(strlen(utf8String) + 1);
                strcpy(ptr.get(), utf8String);
                configs.push_back(ptr.get());
                configPtrs.push_back(std::move(ptr));
            }
        }

        // Initialize Tesseract with current configuration
        if (!_tesseract) {
            _tesseract = std::make_unique<tesseract::TessBaseAPI>();
        }

        // Pass the address of our vectors - this creates const pointers to our non-const vectors
        int returnCode = _tesseract->Init(
                                          self.absoluteDataPath.fileSystemRepresentation,
                                          self.language.UTF8String,
                                          (tesseract::OcrEngineMode)self.engineMode,
                                          configs.empty() ? nullptr : configs.data(),
                                          static_cast<int>(configs.size()),
                                          vars_vec.empty() ? nullptr : &vars_vec,
                                          vars_values.empty() ? nullptr : &vars_values,
                                          false
                                          );

        return returnCode == 0;

    } catch (const std::exception& e) {
        NSLog(@"Error configuring Tesseract engine: %s", e.what());
        return NO;
    }
}

- (void)fillVectors:(std::vector<std::string>&)vars_vec values:(std::vector<std::string>&)vars_values fromDictionary:(NSDictionary*)dict {
    vars_vec.reserve(dict.count);
    vars_values.reserve(dict.count);

    [dict enumerateKeysAndObjectsUsingBlock: ^(NSString *key, NSString *value, BOOL *stop) {
        vars_vec.push_back(std::string([key UTF8String]));
        vars_values.push_back(std::string([value UTF8String]));
    }];
}

- (void)resetFlags
{
    self.recognized = NO;
    self.layoutAnalysed = NO;
}

/**
 * Resets and reconfigures the Tesseract engine with current settings
 * @return YES if engine was successfully reset and configured
 */
- (BOOL)resetEngine {
    BOOL isInitDone = [self configEngine];
    if (isInitDone) {
        [self loadVariables];
        [self setOtherCachedValues];
        [self resetFlags];
    } else {
        NSLog(@"ERROR! Can't init Tesseract engine.");
        _language = nil;
        _tesseract.reset();
    }
    return isInitDone;
}

/**
 * Applies cached configuration values to the engine
 */
- (void)setOtherCachedValues {
    if (_image) {
        [self setEngineImage:_image];
    }
    [self setSourceResolution:_sourceResolution];
    [self setEngineRect:_rect];
    [self setVariableValue:_charWhitelist forKey:kG8ParamTesseditCharWhitelist];
    [self setVariableValue:_charBlacklist forKey:kG8ParamTesseditCharBlacklist];
    [self setVariableValue:[NSString stringWithFormat:@"%lu", (unsigned long)_pageSegmentationMode]
                    forKey:kG8ParamTesseditPagesegMode];
}

/**
 * Ensures tessdata is available in the target directory
 * @param directoryPath Target directory for tessdata
 * @return YES if tessdata is ready for use
 */
- (BOOL)moveTessdataToDirectoryIfNecessary:(NSString *)directoryPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // Setup paths
    NSString *tessdataFolderName = @"tessdata";
    NSString *tessdataPath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:tessdataFolderName];
    NSString *destinationPath = [directoryPath stringByAppendingPathComponent:tessdataFolderName];
    NSLog(@"Tesseract destination path: %@", destinationPath);

    BOOL isDirectory = YES;
    if (![fileManager fileExistsAtPath:tessdataPath isDirectory:&isDirectory] || !isDirectory) {
        return NO;  // No tessdata directory in bundle
    }

    // Create destination directory if needed
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:destinationPath]) {
        if (![fileManager createDirectoryAtPath:destinationPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Error creating folder %@: %@", destinationPath, error);
            return NO;
        }
    }

    BOOL result = YES;
    NSArray *files = [fileManager contentsOfDirectoryAtPath:tessdataPath error:&error];
    if (!files) {
        NSLog(@"ERROR! %@", error.description);
        return NO;
    }

    // Create symlinks for each file
    for (NSString *filename in files) {
        NSString *destinationFileName = [destinationPath stringByAppendingPathComponent:filename];
        if (![fileManager fileExistsAtPath:destinationFileName]) {
            NSString *filePath = [tessdataPath stringByAppendingPathComponent:filename];

            // Remove any broken symlinks first
            [fileManager removeItemAtPath:destinationFileName error:nil];

            // Create new symlink
            if (![fileManager createSymbolicLinkAtPath:destinationFileName withDestinationPath:filePath error:&error]) {
                NSLog(@"Error creating symlink %@: %@", destinationPath, error);
                result = NO;
            }
        }
    }

    return result;
}

/**
 * Sets a Tesseract variable value for the given key.
 * All variables are stored for engine reinitialization.
 * Only runtime variables can be modified after initialization.
 *
 * @param value The value to set. If nil, empty string is used.
 * @param key The variable key name.
 */
- (void)setVariableValue:(NSString *)value forKey:(NSString *)key {
    /*
     * Example:
     * _tesseract->SetVariable("tessedit_char_whitelist", "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ");
     * _tesseract->SetVariable("language_model_penalty_non_freq_dict_word", "0");
     * _tesseract->SetVariable("language_model_penalty_non_dict_word ", "0");
     */

    [self resetFlags];  // Reset recognition state

    value = value ?: @"";
    self.variables[key] = value;

    if (self.isEngineConfigured) {
        _tesseract->SetVariable(key.UTF8String, value.UTF8String);
    }
}

/**
 * Retrieves the value of a Tesseract variable for the given key.
 *
 * @param key The variable key name
 * @return The variable value, or nil if not set or engine not configured
 */
- (NSString *)variableValueForKey:(NSString *)key {
    if (!self.isEngineConfigured) {
        return self.variables[key];
    }

    std::string val;
    if (_tesseract->GetVariableAsString(key.UTF8String, &val)) {
        return [NSString stringWithUTF8String:val.c_str()];
    }
    return nil;
}

/**
 * Sets multiple Tesseract variables at once from a dictionary.
 *
 * @param dictionary Dictionary of key-value pairs to set
 */
- (void)setVariablesFromDictionary:(NSDictionary *)dictionary {
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [self setVariableValue:value forKey:key];
    }];
}

/**
 * Loads all stored variables into the Tesseract engine.
 * Called during engine initialization/reset.
 */
- (void)loadVariables {
    if (self.isEngineConfigured) {
        [self.variables enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            self->_tesseract->SetVariable(key.UTF8String, value.UTF8String);
        }];
    }
}

#pragma mark - Internal getters and setters

- (void)setEngineImage:(UIImage *)image {
    if (image.size.width <= 0 || image.size.height <= 0) {
        NSLog(@"ERROR: Image has invalid size!");
        return;
    }

    self.imageSize = image.size;

    if (!_tesseract) {
        NSLog(@"ERROR: Tesseract engine is null");
        _image = image;
        [self resetFlags];
        return;
    }

    std::unique_ptr<g8::PixWrapper> pix;  // Will be nullptr by default

    if ([self.delegate respondsToSelector:@selector(preprocessedImageForTesseract:sourceImage:)]) {
        UIImage *thresholdedImage = [self.delegate preprocessedImageForTesseract:self sourceImage:image];
        if (thresholdedImage != nil) {
            self.imageSize = thresholdedImage.size;

            // Get preprocessed pix
            auto preprocessedPix = [self pixForImage:thresholdedImage];
            if (preprocessedPix) {
                Pix* rawPreprocessedPix = preprocessedPix->get();
                if (rawPreprocessedPix) {
                    // Convert to binary
                    Pix* thresholdedPix = pixConvertTo1(rawPreprocessedPix, UINT8_MAX / 2);
                    if (thresholdedPix) {
                        pix = std::make_unique<g8::PixWrapper>(thresholdedPix);
                    }
                }
            }

            if (!pix) {
                NSLog(@"WARNING: Can't create Pix for custom thresholded image!");
            }
        }
    }

    // If preprocessing failed or wasn't requested, try original image
    if (!pix) {
        pix = [self pixForImage:image];
    }

    // Set the image if we have a valid pix
    if (pix && pix->get()) {
        @try {
            auto *api = _tesseract.get();
            if (api) {
                api->SetImage(pix->get());
            }
        }
        @catch (NSException *exception) {
            NSLog(@"ERROR: Can't set image: %@", exception);
        }
    }

    _image = image;
    [self resetFlags];
}

/**
 * Sets the source resolution for the Tesseract engine
 * @param sourceResolution Resolution in DPI
 */
- (void)setEngineSourceResolution:(NSUInteger)sourceResolution {
    if (self.isEngineConfigured) {
        _tesseract->SetSourceResolution((int)sourceResolution);
    }
}

/**
 * Sets the recognition rectangle for the Tesseract engine
 * Adjusts coordinates based on potential preprocessing scale changes
 * @param rect The rectangle in the image to process
 */
- (void)setEngineRect:(CGRect)rect {
    if (!self.isEngineConfigured) {
        return;
    }

    CGFloat x = CGRectGetMinX(rect);
    CGFloat y = CGRectGetMinY(rect);
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);

    // Adjust for scale changes from preprocessing
    if (!CGSizeEqualToSize(self.image.size, self.imageSize)) {
        CGFloat widthFactor = self.imageSize.width / self.image.size.width;
        CGFloat heightFactor = self.imageSize.height / self.image.size.height;

        x *= widthFactor;
        y *= heightFactor;
        width *= widthFactor;
        height *= heightFactor;
    }

    // Clip rect coordinates to image bounds
    auto clip = [](CGFloat value, CGFloat min, CGFloat max) -> CGFloat {
        return (value < min ? min : (value > max ? max : value));
    };

    x = clip(x, 0, self.imageSize.width);
    y = clip(y, 0, self.imageSize.height);
    width = clip(width, 0, self.imageSize.width - x);
    height = clip(height, 0, self.imageSize.height - y);

    _tesseract->SetRectangle(x, y, width, height);
}

#pragma mark - Public getters and setters

/**
 * Sets OCR language. Changes require engine reset.
 * @param language Language code (e.g., "eng" for English)
 */
- (void)setLanguage:(NSString *)language {
    if ([language isEqualToString:_language] == NO || (!language && _language)) {
        _language = language.copy;
        if (!self.language) {
            NSLog(@"WARNING: Setting G8Tesseract language to nil defaults to English. "
                  "Make sure you either set the language afterward or have eng.traineddata "
                  "in your tessdata folder, otherwise Tesseract will crash!");
        }
        [self resetEngine];
    }
}

- (void)setEngineMode:(G8OCREngineMode)engineMode
{
    if (_engineMode != engineMode) {
        _engineMode = engineMode;

        [self resetEngine];
    }
}

/**
 * Sets page segmentation mode
 * @param pageSegmentationMode The segmentation mode to use
 */
- (void)setPageSegmentationMode:(G8PageSegmentationMode)pageSegmentationMode {
    if (_pageSegmentationMode != pageSegmentationMode) {
        _pageSegmentationMode = pageSegmentationMode;
        [self setVariableValue:[NSString stringWithFormat:@"%lu", (unsigned long)pageSegmentationMode]
                        forKey:kG8ParamTesseditPagesegMode];
    }
}

/**
 * Sets character whitelist for recognition
 * Note: Only works in TesseractOnly mode
 * @param charWhitelist String of allowed characters
 */
- (void)setCharWhitelist:(NSString *)charWhitelist {
    if ([_charWhitelist isEqualToString:charWhitelist] == NO) {
        _charWhitelist = charWhitelist.copy;
        [self setVariableValue:_charWhitelist forKey:kG8ParamTesseditCharWhitelist];
    }
}

/**
 * Sets character blacklist for recognition
 * Note: Only works in TesseractOnly mode
 * @param charBlacklist String of disallowed characters
 */
- (void)setCharBlacklist:(NSString *)charBlacklist {
    if ([_charBlacklist isEqualToString:charBlacklist] == NO) {
        _charBlacklist = charBlacklist.copy;
        [self setVariableValue:_charBlacklist forKey:kG8ParamTesseditCharBlacklist];
    }
}

/**
 * Sets the image to be processed
 * @param image The UIImage to process
 */
- (void)setImage:(UIImage *)image {
    if (_image != image) {
        [self setEngineImage:image];
        _rect = (CGRect){CGPointZero, self.imageSize};
    }
}

/**
 * Sets the region of interest for recognition
 * @param rect The rectangle to process in the image
 */
- (void)setRect:(CGRect)rect {
    if (!CGRectEqualToRect(_rect, rect)) {
        _rect = rect;
        [self setEngineRect:_rect];
        [self resetFlags];
    }
}

/**
 * Sets source resolution, clamping to valid range
 * @param sourceResolution Resolution in DPI
 */
- (void)setSourceResolution:(NSUInteger)sourceResolution {
    if (_sourceResolution != sourceResolution) {
        // Clamp resolution to valid range
        if (sourceResolution > kG8MaxCredibleResolution) {
            NSLog(@"Source resolution is too big: %lu > %lu",
                  (unsigned long)sourceResolution,
                  (unsigned long)kG8MaxCredibleResolution);
            sourceResolution = kG8MaxCredibleResolution;
        }
        else if (sourceResolution < kG8MinCredibleResolution) {
            NSLog(@"Source resolution is too small: %lu < %lu",
                  (unsigned long)sourceResolution,
                  (unsigned long)kG8MinCredibleResolution);
            sourceResolution = kG8MinCredibleResolution;
        }

        _sourceResolution = sourceResolution;
        [self setEngineSourceResolution:_sourceResolution];
    }
}

/**
 * Gets the current recognition progress
 * @return Progress percentage (0-100)
 */
- (NSUInteger)progress {
    if (!_monitor) {
        return 0;
    }
    return _monitor->get()->progress;
}

/**
 * Checks if the Tesseract engine is properly configured
 * @return YES if engine is ready for use
 */
- (BOOL)isEngineConfigured {
    if (!_tesseract) {
        return NO;
    }
    auto *api = _tesseract.get();
    return (api != nullptr);
}

#pragma mark - Result fetching

/**
 * Returns the recognized text from the image
 * @return UTF8 string of recognized text, or nil if recognition failed
 */
- (NSString *)recognizedText {
    if (!self.isEngineConfigured) {
        NSLog(@"Error! Cannot get recognized text because the Tesseract engine is not properly configured!");
        return nil;
    }

    std::unique_ptr<char[]> utf8Text(_tesseract->GetUTF8Text());
    if (!utf8Text) {
        NSLog(@"No recognized text. Check that -[Tesseract setImage:] is passed an image bigger than 0x0.");
        return nil;
    }

    return [NSString stringWithUTF8String:utf8Text.get()];
}

- (G8Orientation)orientation
{
    [self analyseLayout];
    return _orientation;
}

- (G8WritingDirection)writingDirection
{
    [self analyseLayout];
    return _writingDirection;
}

- (G8TextlineOrder)textlineOrder
{
    [self analyseLayout];
    return _textlineOrder;
}

- (CGFloat)deskewAngle
{
    [self analyseLayout];
    return _deskewAngle;
}

/**
 * Analyzes the page layout if not already done
 * Updates orientation, writing direction, and other layout properties
 */
- (void)analyseLayout {
    // Skip if already analyzed
    if (self.layoutAnalysed) return;

    if (!self.isEngineConfigured) {
        NSLog(@"Error! Cannot perform layout analysis because the engine is not properly configured!");
        return;
    }

    std::unique_ptr<tesseract::PageIterator> iterator(_tesseract->AnalyseLayout());
    if (!iterator) {
        NSLog(@"Can't analyse layout. Make sure 'osd.traineddata' is available in 'tessdata'.");
        return;
    }

    tesseract::Orientation orientation;
    tesseract::WritingDirection direction;
    tesseract::TextlineOrder order;
    float deskewAngle;

    iterator->Orientation(&orientation, &direction, &order, &deskewAngle);

    self.orientation = (G8Orientation)orientation;
    self.writingDirection = (G8WritingDirection)direction;
    self.textlineOrder = (G8TextlineOrder)order;
    self.deskewAngle = deskewAngle;

    self.layoutAnalysed = YES;
}

- (CGRect)normalizedRectForX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height {
    x /= self.imageSize.width;
    y /= self.imageSize.height;
    width /= self.imageSize.width;
    height /= self.imageSize.height;
    return CGRectMake(x, y, width, height);
}

/**
 * Creates a single recognized block from a result iterator
 * @param iterator Result iterator at current position
 * @param iteratorLevel Level of recognition detail
 * @return Recognized block or nil if no text found
 */
- (G8RecognizedBlock *)blockFromIterator:(tesseract::ResultIterator *)iterator
                           iteratorLevel:(G8PageIteratorLevel)iteratorLevel {
    if (!iterator) return nil;

    tesseract::PageIteratorLevel level = (tesseract::PageIteratorLevel)iteratorLevel;

    std::unique_ptr<char[]> utf8Text(iterator->GetUTF8Text(level));
    if (!utf8Text) return nil;

    // Get bounding box coordinates (Left, Top, Right, Bottom)
    int x1, y1, x2, y2;
    iterator->BoundingBox(level, &x1, &y1, &x2, &y2);

    CGFloat x = x1;
    CGFloat y = y1;
    CGFloat width = x2 - x1;
    CGFloat height = y2 - y1;

    NSString *text = [NSString stringWithUTF8String:utf8Text.get()];
    CGRect boundingBox = [self normalizedRectForX:x y:y width:width height:height];
    CGFloat confidence = iterator->Confidence(level);

    return [[G8RecognizedBlock alloc] initWithText:text
                                       boundingBox:boundingBox
                                        confidence:confidence
                                             level:iteratorLevel];
}

/**
 * Creates a hierarchical recognized block including font attributes and character choices
 */
- (G8HierarchicalRecognizedBlock *)hierarchicalBlockFromIterator:(tesseract::ResultIterator *)iterator
                                                   iteratorLevel:(G8PageIteratorLevel)iteratorLevel {
    if (!iterator) return nil;

    G8RecognizedBlock *baseBlock = [self blockFromIterator:iterator iteratorLevel:iteratorLevel];
    if (!baseBlock) return nil;

    G8HierarchicalRecognizedBlock *block = [[G8HierarchicalRecognizedBlock alloc] initWithBlock:baseBlock];

    // Handle word-level attributes
    if (iteratorLevel == G8PageIteratorLevelWord) {
        bool isBold, isItalic, isUnderlined, isMonospace, isSerif, isSmallcaps;
        int pointsize, fontId;

        @try {
            iterator->WordFontAttributes(&isBold, &isItalic, &isUnderlined, &isMonospace,
                                         &isSerif, &isSmallcaps, &pointsize, &fontId);

            block.isFromDict = iterator->WordIsFromDictionary();
            block.isNumeric = iterator->WordIsNumeric();
            block.isBold = isBold;
            block.isItalic = isItalic;
        } @catch (NSException *exception) {
            NSLog(@"Error getting word attributes: %@", exception);
        }
    }
    // Handle symbol-level choices
    else if (iteratorLevel == G8PageIteratorLevelSymbol) {
        NSMutableArray<G8RecognizedBlock *> *choices = [NSMutableArray array];

        // Scope the ChoiceIterator
        @try {
            // Create choice iterator in its own scope
            {
                tesseract::ChoiceIterator choiceIt(*iterator);

                do {
                    const char* text = choiceIt.GetUTF8Text();
                    if (text) {
                        @autoreleasepool {
                            NSString *choiceText = [NSString stringWithUTF8String:text];
                            CGFloat confidence = choiceIt.Confidence();

                            G8RecognizedBlock *choiceBlock = [[G8RecognizedBlock alloc]
                                                              initWithText:choiceText
                                                              boundingBox:block.boundingBox
                                                              confidence:confidence
                                                              level:G8PageIteratorLevelSymbol];
                            [choices addObject:choiceBlock];
                        }
                    }
                } while (choiceIt.Next());
            }
            // ChoiceIterator is automatically destroyed here
        } @catch (NSException *exception) {
            NSLog(@"Error processing symbol choices: %@", exception);
        }

        if (choices.count > 0) {
            block.characterChoices = [choices copy];
        }
    }

    return block;
}

/**
 * Gets all character choices from the recognition results
 * @return Array of arrays containing character alternatives
 */
- (NSArray *)characterChoices {
    if (!self.isEngineConfigured) return nil;

    NSMutableArray *resultArray = [NSMutableArray array];
    std::unique_ptr<tesseract::ResultIterator> iterator(_tesseract->GetIterator());

    if (!iterator) return nil;

    // Move through symbols
    do {
        NSMutableArray *choices = [NSMutableArray array];

        // Scope the ChoiceIterator so it's properly destroyed before Next() is called
        {
            // Create a new choice iterator for current symbol
            tesseract::ChoiceIterator choiceIt(*iterator);

            // Get bounding box for current symbol
            int x1, y1, x2, y2;
            iterator->BoundingBox(tesseract::RIL_SYMBOL, &x1, &y1, &x2, &y2);
            CGRect boundingBox = [self normalizedRectForX:x1 y:y1
                                                    width:(x2 - x1)
                                                   height:(y2 - y1)];

            // Collect all choices for current symbol
            do {
                const char* choiceText = choiceIt.GetUTF8Text();
                if (choiceText) {
                    NSString *text = [NSString stringWithUTF8String:choiceText];
                    CGFloat confidence = choiceIt.Confidence();

                    G8RecognizedBlock *choiceBlock = [[G8RecognizedBlock alloc]
                                                      initWithText:text
                                                      boundingBox:boundingBox
                                                      confidence:confidence
                                                      level:G8PageIteratorLevelSymbol];

                    [choices addObject:choiceBlock];
                }
            } while (choiceIt.Next());
        }

        if (choices.count > 0) {
            [resultArray addObject:[choices copy]];
        }

    } while (iterator->Next(tesseract::RIL_SYMBOL));

    return [resultArray copy];
}

/**
 * Gets recognized blocks organized in a hierarchical structure for the given iterator level
 * @param pageIteratorLevel The level of detail to recognize (block, paragraph, line, word, symbol)
 * @return Array of hierarchical recognized blocks or nil if engine not configured
 */
- (NSArray *)recognizedHierarchicalBlocksByIteratorLevel:(G8PageIteratorLevel)pageIteratorLevel {
    if (!self.isEngineConfigured) {
        return nil;
    }

    std::unique_ptr<tesseract::ResultIterator> resultIterator(_tesseract->GetIterator());
    if (!resultIterator) {
        return nil;
    }

    return [self getBlocksFromIterator:resultIterator.get()
                              forLevel:pageIteratorLevel
                          highestLevel:pageIteratorLevel];
}

/**
 * Recursive helper to build hierarchical block structure
 * @param resultIterator Iterator at current position
 * @param pageIteratorLevel Current level being processed
 * @param highestLevel Top-most level requested
 * @return Array of hierarchical blocks at current level
 */
- (NSArray *)getBlocksFromIterator:(tesseract::ResultIterator *)resultIterator
                          forLevel:(G8PageIteratorLevel)pageIteratorLevel
                      highestLevel:(G8PageIteratorLevel)highestLevel {

    if (!resultIterator) return nil;

    NSMutableArray *blocks = [[NSMutableArray alloc] init];
    tesseract::PageIteratorLevel level = (tesseract::PageIteratorLevel)pageIteratorLevel;

    BOOL endOfBlock = NO;

    do {
        // Create block for current position
        G8HierarchicalRecognizedBlock *block = [self hierarchicalBlockFromIterator:resultIterator
                                                                     iteratorLevel:pageIteratorLevel];
        if (!block) continue;

        [blocks addObject:block];

        // Recursively process child blocks if not at symbol level
        if (pageIteratorLevel != G8PageIteratorLevelSymbol) {
            block.childBlocks = [self getBlocksFromIterator:resultIterator
                                                   forLevel:[self getDeeperIteratorLevel:pageIteratorLevel]
                                               highestLevel:highestLevel];
        }

        // Check if we've reached the end of current block
        endOfBlock = (pageIteratorLevel != highestLevel &&
                      resultIterator->IsAtFinalElement((tesseract::PageIteratorLevel)[self getHigherIteratorLevel:pageIteratorLevel],
                                                       level)) ||
        !resultIterator->Next(level);

    } while (!endOfBlock);

    return [blocks copy];
}

/**
 * Gets the next deeper iterator level in the hierarchy
 * @param iteratorLevel Current level
 * @return Next deeper level
 */
- (G8PageIteratorLevel)getDeeperIteratorLevel:(G8PageIteratorLevel)iteratorLevel {
    switch (iteratorLevel) {
        case G8PageIteratorLevelBlock:
            return G8PageIteratorLevelParagraph;
        case G8PageIteratorLevelParagraph:
            return G8PageIteratorLevelTextline;
        case G8PageIteratorLevelTextline:
            return G8PageIteratorLevelWord;
        case G8PageIteratorLevelWord:
            return G8PageIteratorLevelSymbol;
        case G8PageIteratorLevelSymbol:
            return G8PageIteratorLevelSymbol;
    }
}

/**
 * Gets the next higher iterator level in the hierarchy
 * @param iteratorLevel Current level
 * @return Next higher level
 */
- (G8PageIteratorLevel)getHigherIteratorLevel:(G8PageIteratorLevel)iteratorLevel {
    switch (iteratorLevel) {
        case G8PageIteratorLevelBlock:
            return G8PageIteratorLevelBlock;
        case G8PageIteratorLevelParagraph:
            return G8PageIteratorLevelBlock;
        case G8PageIteratorLevelTextline:
            return G8PageIteratorLevelParagraph;
        case G8PageIteratorLevelWord:
            return G8PageIteratorLevelTextline;
        case G8PageIteratorLevelSymbol:
            return G8PageIteratorLevelWord;
    }
}

/**
 * Gets recognized blocks at a specific iterator level without hierarchy
 * @param pageIteratorLevel Level to recognize
 * @return Array of recognized blocks or nil if engine not configured
 */
- (NSArray *)recognizedBlocksByIteratorLevel:(G8PageIteratorLevel)pageIteratorLevel {
    if (!self.isEngineConfigured) {
        return nil;
    }

    NSMutableArray *blocks = [NSMutableArray array];
    std::unique_ptr<tesseract::ResultIterator> resultIterator(_tesseract->GetIterator());

    if (resultIterator) {
        tesseract::PageIteratorLevel level = (tesseract::PageIteratorLevel)pageIteratorLevel;

        do {
            G8RecognizedBlock *block = [self blockFromIterator:resultIterator.get()
                                                 iteratorLevel:pageIteratorLevel];
            if (block) {
                [blocks addObject:block];
            }
        } while (resultIterator->Next(level));
    }

    return [blocks copy];
}

/**
 * Generates HOCR format output for the given page
 * @param pageNumber Page number (0-based)
 * @return HOCR string or nil if engine not configured
 */
- (NSString *)recognizedHOCRForPageNumber:(int)pageNumber {
    if (!self.isEngineConfigured) {
        return nil;
    }

    std::unique_ptr<char[]> hocr(_tesseract->GetHOCRText(pageNumber));
    if (!hocr) {
        return nil;
    }

    return [NSString stringWithUTF8String:hocr.get()];
}

/**
 * Generates a searchable PDF from recognized text
 * @param images Array of images to process
 * @return PDF data or nil if engine not configured
 */
- (NSData *)recognizedPDFForImages:(NSArray *)images {
    if (!self.isEngineConfigured) {
        return nil;
    }

    // Setup paths
    NSString *tempDir = NSTemporaryDirectory();
    NSString *tempFileName = [[NSUUID UUID].UUIDString stringByDeletingPathExtension];
    NSString *outputBase = [tempDir stringByAppendingPathComponent:tempFileName];
    NSString *tessdataPath = self.absoluteDataPath;

    // Create renderer
    std::unique_ptr<tesseract::TessResultRenderer> renderer;
    try {
        renderer.reset(new tesseract::TessPDFRenderer(
                                                      outputBase.UTF8String,
                                                      tessdataPath.fileSystemRepresentation
                                                      ));

        if (!renderer || !renderer->BeginDocument("Tesseract OCR")) {
            return nil;
        }

        // Process each image
        for (int pageIndex = 0; pageIndex < images.count; pageIndex++) {
            UIImage *image = images[pageIndex];
            if (![image isKindOfClass:[UIImage class]]) {
                continue;
            }

            auto pix = [self pixForImage:image];
            if (!pix || !pix->get()) {
                continue;
            }

            if (!_tesseract->ProcessPage(pix->get(), pageIndex, "", nullptr, 0, renderer.get())) {
                return nil;
            }
        }

        if (!renderer->EndDocument()) {
            return nil;
        }

    } catch (const std::exception&) {
        return nil;
    }

    // Clean up renderer before reading file
    renderer.reset();

    // Read the generated PDF
    NSString *outputPath = [outputBase stringByAppendingPathExtension:@"pdf"];
    NSData *pdfData = [NSData dataWithContentsOfFile:outputPath];

    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];

    return pdfData;
}

- (UIImage *)imageWithBlocks:(NSArray *)blocks drawText:(BOOL)drawText thresholded:(BOOL)thresholded {
    UIImage *image = thresholded ? self.thresholdedImage : self.image;

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:image.size];
    UIImage *outputImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext *rendererContext) {
        CGContextRef context = rendererContext.CGContext;
        [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];

        CGContextSetLineWidth(context, 2.0);
        CGContextSetStrokeColorWithColor(context, UIColor.redColor.CGColor);

        for (G8RecognizedBlock *block in blocks) {
            CGRect boundingBox = [block boundingBoxAtImageOfSize:image.size];
            CGContextStrokeRect(context, boundingBox);

            if (drawText) {
                NSDictionary *attributes = @{NSForegroundColorAttributeName: UIColor.redColor};
                NSAttributedString *string = [[NSAttributedString alloc] initWithString:block.text attributes:attributes];
                CGPoint textPosition = CGPointMake(CGRectGetMidX(boundingBox), CGRectGetMaxY(boundingBox) + 2);
                [string drawAtPoint:textPosition];
            }
        }
    }];

    return outputImage;
}

#pragma mark - Other functions

- (BOOL)recognize {
    if (!self.isEngineConfigured) {
        NSLog(@"[Error] Tesseract engine is not properly configured for recognition.");
        return NO;
    }

    // Set recognition deadline using the wrapper
    if (self.maximumRecognitionTime > FLT_EPSILON) {
        _monitor->setDeadline(static_cast<int>(self.maximumRecognitionTime * 1000));
    }

    self.recognized = NO;
    int returnCode = 0;

    @try {
        returnCode = _tesseract->Recognize(_monitor->get());
        self.recognized = (returnCode == 0);
    }
    @catch (NSException *exception) {
        NSLog(@"[Exception] Recognition process encountered an error: %@", exception);
    }

    return self.recognized;
}

- (UIImage *)thresholdedImage {
    if (!self.isEngineConfigured) {
        return nil;
    }

    // Step 1: Get the thresholded image and wrap it in PixWrapper
    g8::PixWrapper pixs(_tesseract->GetThresholdedImage());
    if (!pixs) {
        return nil;
    }

    Pix* rawPixs = pixs.get();
    if (!rawPixs) {
        return nil;
    }

    // Step 2: Unpack binary data and wrap in PixWrapper
    g8::PixWrapper unpackedPix(pixUnpackBinary(rawPixs, 32, 0));
    if (!unpackedPix) {
        return nil;
    }

    Pix* rawUnpackedPix = unpackedPix.get();
    if (!rawUnpackedPix) {
        return nil;
    }

    // Step 3: Convert to UIImage
    return [self imageFromPix:rawUnpackedPix];
}

- (UIImage *)imageFromPix:(Pix *)pix {
    if (!pix) return nil;

    // Wrap incoming Pix* in PixWrapper to ensure cleanup
    g8::PixWrapper pixWrapper(pix);

    l_uint32 width = pixGetWidth(pix);
    l_uint32 height = pixGetHeight(pix);
    l_uint32 bitsPerPixel = pixGetDepth(pix);
    l_uint32 bytesPerRow = pixGetWpl(pix) * 4;
    l_uint32 bitsPerComponent = 8;

    // By default, Leptonica uses 3 samples per pixel (RGB); here, we ensure it's 4 for RGBA
    if (pixSetSpp(pix, 4) == 0) {
        bitsPerComponent = bitsPerPixel / pixGetSpp(pix);
    }

    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, pixGetData(pix), bytesPerRow * height, NULL);
    if (!provider) return nil;
    std::unique_ptr<CGDataProvider, decltype(&CGDataProviderRelease)> providerPtr(provider, CGDataProviderRelease);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (!colorSpace) return nil;
    std::unique_ptr<CGColorSpace, decltype(&CGColorSpaceRelease)> colorSpacePtr(colorSpace, CGColorSpaceRelease);

    CGImageRef cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow,
                                       colorSpace, (CGBitmapInfo)kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast,
                                       provider, NULL, NO, kCGRenderingIntentDefault);
    if (!cgImage) return nil;
    std::unique_ptr<CGImage, decltype(&CGImageRelease)> cgImagePtr(cgImage, CGImageRelease);

    // Draw CGImage to create UIImage - workaround for rendering issues
    CGRect frame = { CGPointZero, CGSizeMake(width, height) };
    UIGraphicsBeginImageContextWithOptions(frame.size, YES, self.image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Flip the context vertically
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, frame, cgImage);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

/**
 * Creates a Pix object from a UIImage, handling different image orientations and bit depths
 * @param image Source UIImage to convert
 * @return Unique pointer to PixWrapper containing the converted image
 */
- (std::unique_ptr<g8::PixWrapper>)pixForImage:(UIImage *)image {
    int width = image.size.width;
    int height = image.size.height;

    if (width <= 0 || height <= 0) {
        return nullptr;
    }

    CGImage *cgImage = image.CGImage;
    CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
    if (!imageData) {
        return nullptr;
    }

    const UInt8 *pixels = CFDataGetBytePtr(imageData);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(cgImage);
    size_t bytesPerPixel = bitsPerPixel / 8;
    size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);

    int bpp = MAX(1, (int)bitsPerPixel);
    Pix *pix = pixCreate(width, height, bpp == 24 ? 32 : bpp);
    if (!pix) {
        CFRelease(imageData);
        return nullptr;
    }

    // Create RAII wrapper for the Pix
    auto pixWrapper = std::make_unique<g8::PixWrapper>(pix);

    l_uint32 *data = pixGetData(pix);
    int wpl = pixGetWpl(pix);

    // Rest of the pixForImage implementation remains the same until the end
    void (^copyBlock)(l_uint32 *toAddr, NSUInteger toOffset, const UInt8 *fromAddr, NSUInteger fromOffset) = nil;
    switch (bpp) {
        case 8: {
            copyBlock = ^(l_uint32 *toAddr, NSUInteger toOffset, const UInt8 *fromAddr, NSUInteger fromOffset) {
                SET_DATA_BYTE(toAddr, toOffset, fromAddr[fromOffset]);
            };
            break;
        }
        case 32: {
            copyBlock = ^(l_uint32 *toAddr, NSUInteger toOffset, const UInt8 *fromAddr, NSUInteger fromOffset) {
                toAddr[toOffset] = (fromAddr[fromOffset] << 24) | (fromAddr[fromOffset + 1] << 16) |
                (fromAddr[fromOffset + 2] << 8) | fromAddr[fromOffset + 3];
            };
            break;
        }
        default:
            NSLog(@"Cannot convert image to Pix with bpp = %d", bpp);
            CFRelease(imageData);
            return nullptr;
    }

    // Original orientation handling code stays the same
    if (copyBlock) {
        switch (image.imageOrientation) {
            case UIImageOrientationUp:
                // Maintain byte order consistency across different endianness.
                for (int y = 0; y < height; ++y, pixels += bytesPerRow, data += wpl) {
                    for (int x = 0; x < width; ++x) {
                        copyBlock(data, x, pixels, x * bytesPerPixel);
                    }
                }
                break;

            case UIImageOrientationUpMirrored:
                // Maintain byte order consistency across different endianness.
                for (int y = 0; y < height; ++y, pixels += bytesPerRow, data += wpl) {
                    int maxX = width - 1;
                    for (int x = maxX; x >= 0; --x) {
                        copyBlock(data, maxX - x, pixels, x * bytesPerPixel);
                    }
                }
                break;

            case UIImageOrientationDown:
                // Maintain byte order consistency across different endianness.
                pixels += (height - 1) * bytesPerRow;
                for (int y = height - 1; y >= 0; --y, pixels -= bytesPerRow, data += wpl) {
                    int maxX = width - 1;
                    for (int x = maxX; x >= 0; --x) {
                        copyBlock(data, maxX - x, pixels, x * bytesPerPixel);
                    }
                }
                break;

            case UIImageOrientationDownMirrored:
                // Maintain byte order consistency across different endianness.
                pixels += (height - 1) * bytesPerRow;
                for (int y = height - 1; y >= 0; --y, pixels -= bytesPerRow, data += wpl) {
                    for (int x = 0; x < width; ++x) {
                        copyBlock(data, x, pixels, x * bytesPerPixel);
                    }
                }
                break;

            case UIImageOrientationLeft:
                // Maintain byte order consistency across different endianness.
                for (int x = 0; x < height; ++x, data += wpl) {
                    int maxY = width - 1;
                    for (int y = maxY; y >= 0; --y) {
                        int x0 = y * (int)bytesPerRow + x * (int)bytesPerPixel;
                        copyBlock(data, maxY - y, pixels, x0);
                    }
                }
                break;

            case UIImageOrientationLeftMirrored:
                // Maintain byte order consistency across different endianness.
                for (int x = height - 1; x >= 0; --x, data += wpl) {
                    int maxY = width - 1;
                    for (int y = maxY; y >= 0; --y) {
                        int x0 = y * (int)bytesPerRow + x * (int)bytesPerPixel;
                        copyBlock(data, maxY - y, pixels, x0);
                    }
                }
                break;

            case UIImageOrientationRight:
                // Maintain byte order consistency across different endianness.
                for (int x = height - 1; x >=0; --x, data += wpl) {
                    for (int y = 0; y < width; ++y) {
                        int x0 = y * (int)bytesPerRow + x * (int)bytesPerPixel;
                        copyBlock(data, y, pixels, x0);
                    }
                }
                break;

            case UIImageOrientationRightMirrored:
                // Maintain byte order consistency across different endianness.
                for (int x = 0; x < height; ++x, data += wpl) {
                    for (int y = 0; y < width; ++y) {
                        int x0 = y * (int)bytesPerRow + x * (int)bytesPerPixel;
                        copyBlock(data, y, pixels, x0);
                    }
                }
                break;

            default:
                break;  // LCOV_EXCL_LINE
        }
    }

    pixSetYRes(pix, (l_int32)self.sourceResolution);
    CFRelease(imageData);

    return pixWrapper;
}

- (void)tesseractProgressCallbackFunction:(int)words {
    if ([self.delegate respondsToSelector:@selector(progressImageRecognitionForTesseract:)]) {
        [self.delegate progressImageRecognitionForTesseract:self];
    }
}

- (BOOL)tesseractCancelCallbackFunction:(int)words {
    if (_monitor->get()->ocr_alive == 1) {
        _monitor->get()->ocr_alive = 0;
    }

    [self tesseractProgressCallbackFunction:words];  // Notify progress during cancellation check

    BOOL isCancel = NO;
    if ([self.delegate respondsToSelector:@selector(shouldCancelImageRecognitionForTesseract:)]) {
        isCancel = [self.delegate shouldCancelImageRecognitionForTesseract:self];
    }
    return isCancel;
}

static bool tesseractCancelCallbackFunction(void *cancel_this, int words) {
    G8Tesseract *tesseractInstance = (__bridge G8Tesseract *)cancel_this;
    return [tesseractInstance tesseractCancelCallbackFunction:words];
}

@end
