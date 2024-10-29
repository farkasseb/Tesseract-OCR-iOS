#import <Foundation/Foundation.h>

#ifndef Tesseract_OCR_iOS_G8TesseractParameters_h
#define Tesseract_OCR_iOS_G8TesseractParameters_h

@interface G8TesseractParameters : NSObject

/// Take segmentation and labeling from box file
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditResegmentFromBoxes;

/// Conversion of word/line box file to char box file
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditResegmentFromLineBoxes;

/// Generate training data from boxed chars
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditTrainFromBoxes;

/// Generate more boxes from boxed chars
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditMakeBoxesFromBoxes;

/// Break input into lines and remap boxes if present
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditTrainLineRecognizer;

/// Dump intermediate images made during page segmentation
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditDumpPagesegImages;

/// Try inverted line image if necessary (deprecated, will be removed in release 6, use the 'invert_threshold' parameter instead)
///@param Type bool
///@param Default True
extern NSString *const kG8ParamTesseditDoInvert DEPRECATED_MSG_ATTRIBUTE("Use kG8ParamInvertThreshold instead");

/// For lines with a mean confidence below this value, OCR is also tried with an inverted image
///@param Type double
///@param Default 0.7
extern NSString *const kG8ParamInvertThreshold;

/// The default for pageseg_mode is the old behaviour, so as not to upset anything that relies on that.
/// Page seg mode: 0=osd only, 1=auto+osd, 2=auto_only, 3=auto, 4=column, 5=block_vert, 6=block, 7=line, 8=word, 9=word_circle, 10=char, 11=sparse_text, 12=sparse_text+osd, 13=raw_line
/// (Values from PageSegMode enum in tesseract/publictypes.h)
///@param Type int
///@param Default PSM_SINGLE_BLOCK
extern NSString *const kG8ParamTesseditPagesegMode;

/// Thresholding method: 0 = Otsu, 1 = LeptonicaOtsu, 2 = "Sauvola
///@param Type int
///@param Default ThresholdMethod::Otsu
extern NSString *const kG8ParamThresholdingMethod;

/// Debug the thresholding process
///@param Type bool
///@param Default False
extern NSString *const kG8ParamThresholdingDebug;

/// Window size for measuring local statistics (to be multiplied by image DPI).
/// This parameter is used by the Sauvola thresholding method
///@param Type double
///@param Default 0.33
extern NSString *const kG8ParamThresholdingWindowSize;

/// Factor for reducing threshold due to variance.
/// This parameter is used by the Sauvola thresholding method.
/// Normal range: 0.2-0.5
///@param Type double
///@param Default 0.34
extern NSString *const kG8ParamThresholdingKfactor;

/// Desired tile size (to be multiplied by image DPI).
/// This parameter is used by the LeptonicaOtsu thresholding method
///@param Type double
///@param Default 0.33
extern NSString *const kG8ParamThresholdingTileSize;

/// Size of convolution kernel applied to threshold array (to be multiplied by image DPI). Use 0 for no smoothing.
/// This parameter is used by the LeptonicaOtsu thresholding method
///@param Type double
///@param Default 0.0
extern NSString *const kG8ParamThresholdingSmoothKernelSize;

/// Fraction of the max Otsu score.
/// This parameter is used by the LeptonicaOtsu thresholding method.
/// For standard Otsu use 0.0, otherwise 0.1 is recommended
///@param Type double
///@param Default 0.1
extern NSString *const kG8ParamThresholdingScoreFraction;

/// Which OCR engine(s) to run (Tesseract, LSTM, both).
/// Defaults to loading and running the most accurate available.
///@param Type int
///@param Default tesseract::OEM_DEFAULT
extern NSString *const kG8ParamTesseditOcrEngineMode;

/// Blacklist of chars not to recognize
///@param Type string
///@param Default
extern NSString *const kG8ParamTesseditCharBlacklist;

/// Whitelist of chars to recognize
///@param Type string
///@param Default
extern NSString *const kG8ParamTesseditCharWhitelist;

/// List of chars to override tessedit_char_blacklist
///@param Type string
///@param Default
extern NSString *const kG8ParamTesseditCharUnblacklist;

/// Perform training for ambiguities
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditAmbigsTraining;

/// Whether to use the top-line splitting process for Devanagari documents while performing page-segmentation.
///@param Type int
///@param Default tesseract::ShiroRekhaSplitter::NO_SPLIT
extern NSString *const kG8ParamPagesegDevanagariSplitStrategy;

/// Whether to use the top-line splitting process for Devanagari documents while performing ocr.
///@param Type int
///@param Default tesseract::ShiroRekhaSplitter::NO_SPLIT
extern NSString *const kG8ParamOcrDevanagariSplitStrategy;

/// Write all parameters to the given file.
///@param Type string
///@param Default
extern NSString *const kG8ParamTesseditWriteParamsToFile;

/// Generate and print debug information for adaption
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditAdaptionDebug;

/// Debug level for BiDi
///@param Type int
///@param Default 0
extern NSString *const kG8ParamBidiDebug;

/// Debug level
///@param Type int
///@param Default 1
extern NSString *const kG8ParamApplyboxDebug;

/// Page number to apply boxes from
///@param Type int
///@param Default 0
extern NSString *const kG8ParamApplyboxPage;

/// Exposure value follows this pattern in the image filename. The name of the image files are expected to be in the form [lang].[fontname].exp[num].tif
///@param Type string
///@param Default .exp
extern NSString *const kG8ParamApplyboxExposurePattern;

/// Learn both character fragments (as is done in the special low exposure mode) as well as unfragmented characters.
///@param Type bool
///@param Default False
extern NSString *const kG8ParamApplyboxLearnCharsAndCharFragsMode;

/// Each bounding box is assumed to contain ngrams. Only learn the ngrams whose outlines overlap horizontally.
///@param Type bool
///@param Default False
extern NSString *const kG8ParamApplyboxLearnNgramsMode;

/// Draw output wordss
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditDisplayOutwords;

/// Dump char choices
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditDumpChoices;

/// Print timing stats
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditTimingDebug;

/// Try to improve fuzzy spaces
///@param Type bool
///@param Default True
extern NSString *const kG8ParamTesseditFixFuzzySpaces;

/// Don't bother with word plausibility
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditUnrejAnyWd;

/// Crunch double hyphens?
///@param Type bool
///@param Default True
extern NSString *const kG8ParamTesseditFixHyphens;

/// Add words to the document dictionary
///@param Type bool
///@param Default True
extern NSString *const kG8ParamTesseditEnableDocDict;

/// Output font info per char
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditDebugFonts;

/// Font ID to use or zero
///@param Type int
///@param Default 0
extern NSString *const kG8ParamTesseditFontId;

/// Block and Row stats
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditDebugBlockRejection;

/// Enable correction based on the word bigram dictionary.
///@param Type bool
///@param Default True
extern NSString *const kG8ParamTesseditEnableBigramCorrection;

/// Enable single word correction based on the dictionary.
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditEnableDictCorrection;

/// Amount of debug output for bigram correction.
///@param Type int
///@param Default 0
extern NSString *const kG8ParamTesseditBigramDebug;

/// Remove and conditionally reassign small outlines when they confuse layout analysis, determining diacritics vs noise
///@param Type bool
///@param Default True
extern NSString *const kG8ParamEnableNoiseRemoval;

/// Debug reassignment of small outlines
///@param Type int
///@param Default 0
extern NSString *const kG8ParamDebugNoiseRemoval;

/// Worst (min) certainty, for which a diacritic is allowed to make the base character worse and still be included.
/// Hingepoint for base char certainty
///@param Type double
///@param Default -8.0
extern NSString *const kG8ParamNoiseCertBasechar;

/// Worst (min) certainty, for which a non-overlapping diacritic is allowed to make the base character worse and still be included.
/// Hingepoint for disjoint certainty
///@param Type double
///@param Default -1.0
extern NSString *const kG8ParamNoiseCertDisjoint;

/// Worst (min) certainty, for which a diacritic is allowed to make a new stand-alone blob.
/// Threshold for new punc char certainty
///@param Type double
///@param Default -3.0
extern NSString *const kG8ParamNoiseCertPunc;

/// Factor of certainty margin for adding diacritics to not count as worse.
/// Scaling on certainty diff from Hingepoint
///@param Type double
///@param Default 0.375
extern NSString *const kG8ParamNoiseCertFactor;

/// Max diacritics to apply to a blob
///@param Type int
///@param Default 8
extern NSString *const kG8ParamNoiseMaxPerBlob;

/// Max diacritics to apply to a word
///@param Type int
///@param Default 16
extern NSString *const kG8ParamNoiseMaxPerWord;

/// Reestimate debug
///@param Type int
///@param Default 0
extern NSString *const kG8ParamDebugXHtLevel;

/// Leading punctuation
///@param Type string
///@param Default ('`\"
extern NSString *const kG8ParamChsLeadingPunct;

/// 1st Trailing punctuation
///@param Type string
///@param Default ).,;:?!
extern NSString *const kG8ParamChsTrailingPunct1;

/// 2nd Trailing punctuation
///@param Type string
///@param Default )'`\"
extern NSString *const kG8ParamChsTrailingPunct2;

/// good_quality_doc lte rejection limit
///@param Type double
///@param Default 0.08
extern NSString *const kG8ParamQualityRejPc;

/// good_quality_doc gte good blobs limit
///@param Type double
///@param Default 0.0
extern NSString *const kG8ParamQualityBlobPc;

/// good_quality_doc lte outline error limit
///@param Type double
///@param Default 1.0
extern NSString *const kG8ParamQualityOutlinePc;

/// good_quality_doc gte good char limit
///@param Type double
///@param Default 0.95
extern NSString *const kG8ParamQualityCharPc;

/// alphas in a good word
///@param Type int
///@param Default 2
extern NSString *const kG8ParamQualityMinInitialAlphasReqd;

/// Adaptation decision algorithm for tess
///@param Type int
///@param Default 0x27 (39)
extern NSString *const kG8ParamTesseditTessAdaptionMode;

/// Do minimal rejection on pass 1 output
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditMinimalRejPass1;

/// Test adaption criteria
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditTestAdaption;

/// Test for point
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTestPt;

/// xcoord
///@param Type double
///@param Default 99999.99
extern NSString *const kG8ParamTestPtX;

/// ycoord
///@param Type double
///@param Default 99999.99
extern NSString *const kG8ParamTestPtY;

/// Print multilang debug info.
///@param Type int
///@param Default 0
extern NSString *const kG8ParamMultilangDebugLevel;

/// Print paragraph debug info.
///@param Type int
///@param Default 0
extern NSString *const kG8ParamParagraphDebugLevel;

/// Run paragraph detection on the post-text-recognition (more accurate)
///@param Type bool
///@param Default True
extern NSString *const kG8ParamParagraphTextBased;

/// Use ratings matrix/beam search with lstm
///@param Type bool
///@param Default 1
extern NSString *const kG8ParamLstmUseMatrix;

/// Non standard number of outlines
///@param Type string
///@param Default %|
extern NSString *const kG8ParamOutlinesOdd;

/// Non standard number of outlines
///@param Type string
///@param Default ij!?%":;
extern NSString *const kG8ParamOutlines2;

/// Reduce rejection on good docs
///@param Type bool
///@param Default True
extern NSString *const kG8ParamTesseditGoodQualityUnrej;

/// Reject spaces?
///@param Type bool
///@param Default True
extern NSString *const kG8ParamTesseditUseRejectSpaces;

/// %rej allowed before rej whole doc
///@param Type double
///@param Default 65.0
extern NSString *const kG8ParamTesseditRejectDocPercent;

/// %rej allowed before rej whole block
///@param Type double
///@param Default 45.0
extern NSString *const kG8ParamTesseditRejectBlockPercent;

/// %rej allowed before rej whole row
///@param Type double
///@param Default 40.0
extern NSString *const kG8ParamTesseditRejectRowPercent;

/// Number of row rejects in whole word rejects which prevents whole row rejection
///@param Type double
///@param Default 70.0
extern NSString *const kG8ParamTesseditWholeWdRejRowPercent;

/// Only rej partially rejected words in block rejection
///@param Type bool
///@param Default True
extern NSString *const kG8ParamTesseditPreserveBlkRejPerfectWds;

/// Only rej partially rejected words in row rejection
///@param Type bool
///@param Default True
extern NSString *const kG8ParamTesseditPreserveRowRejPerfectWds;

/// Use word segmentation quality metric
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditDontBlkrejGoodWds;

/// Use word segmentation quality metric
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditDontRowrejGoodWds;

/// Only preserve wds longer than this
///@param Type int
///@param Default 2
extern NSString *const kG8ParamTesseditPreserveMinWdLen;

/// Apply row rejection to good docs
///@param Type bool
///@param Default True
extern NSString *const kG8ParamTesseditRowRejGoodDocs;

/// rej good doc wd if more than this fraction rejected
///@param Type double
///@param Default 1.1
extern NSString *const kG8ParamTesseditGoodDocStillRowrejWd;

/// Reject all bad quality wds
///@param Type bool
///@param Default True
extern NSString *const kG8ParamTesseditRejectBadQualWds;

/// Page stats
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditDebugDocRejection;

/// Output data to debug file
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditDebugQualityMetrics;

/// unrej potential with no checks
///@param Type bool
///@param Default False
extern NSString *const kG8ParamBlandUnrej;

/// good_quality_doc gte good char limit
///@param Type double
///@param Default 1.1
extern NSString *const kG8ParamQualityRowrejPc;

/// Mark v.bad words for tilde crunch
///@param Type bool
///@param Default False
extern NSString *const kG8ParamUnlvTildeCrunching;

/// Add font info to hocr output
///@param Type bool
///@param Default False
extern NSString *const kG8ParamHocrFontInfo;

/// Add coordinates for each character to hocr output
///@param Type bool
///@param Default False
extern NSString *const kG8ParamHocrCharBoxes;

/// Before word crunch?
///@param Type bool
///@param Default True
extern NSString *const kG8ParamCrunchEarlyMergeTessFails;

/// Take out ~^ early?
///@param Type bool
///@param Default False
extern NSString *const kG8ParamCrunchEarlyConvertBadUnlvChs;

/// crunch rating lt this
///@param Type double
///@param Default 80.0
extern NSString *const kG8ParamCrunchTerribleRating;

/// As it says
///@param Type bool
///@param Default True
extern NSString *const kG8ParamCrunchTerribleGarbage;

/// crunch garbage cert lt this
///@param Type double
///@param Default -9.0
extern NSString *const kG8ParamCrunchPoorGarbageCert;

/// crunch garbage rating lt this
///@param Type double
///@param Default 60
extern NSString *const kG8ParamCrunchPoorGarbageRate;

/// POTENTIAL crunch rating lt this
///@param Type double
///@param Default 40
extern NSString *const kG8ParamCrunchPotPoorRate;

/// POTENTIAL crunch cert lt this
///@param Type double
///@param Default -8.0
extern NSString *const kG8ParamCrunchPotPoorCert;

/// POTENTIAL crunch rating lt this
///@param Type double
///@param Default 60
extern NSString *const kG8ParamCrunchDelRating;

/// POTENTIAL crunch cert lt this
///@param Type double
///@param Default -10.0
extern NSString *const kG8ParamCrunchDelCert;

/// Del if word ht lt xht x this
///@param Type double
///@param Default 0.7
extern NSString *const kG8ParamCrunchDelMinHt;

/// Del if word ht gt xht x this
///@param Type double
///@param Default 3.0
extern NSString *const kG8ParamCrunchDelMaxHt;

/// Del if word width lt xht x this
///@param Type double
///@param Default 3.0
extern NSString *const kG8ParamCrunchDelMinWidth;

/// Del if word gt xht x this above bl
///@param Type double
///@param Default 1.5
extern NSString *const kG8ParamCrunchDelHighWord;

/// Del if word gt xht x this below bl
///@param Type double
///@param Default 0.5
extern NSString *const kG8ParamCrunchDelLowWord;

/// Small if lt xht x this
///@param Type double
///@param Default 0.6
extern NSString *const kG8ParamCrunchSmallOutlinesSize;

/// For adj length in rating per ch
///@param Type int
///@param Default 10
extern NSString *const kG8ParamCrunchRatingMax;

/// How many potential indicators needed
///@param Type int
///@param Default 1
extern NSString *const kG8ParamCrunchPotIndicators;

/// Don't touch sensible strings
///@param Type bool
///@param Default True
extern NSString *const kG8ParamCrunchLeaveOkStrings;

/// Use acceptability in okstring
///@param Type bool
///@param Default True
extern NSString *const kG8ParamCrunchAcceptOk;

/// Don't pot crunch sensible strings
///@param Type bool
///@param Default False
extern NSString *const kG8ParamCrunchLeaveAcceptStrings;

/// Fiddle alpha figures
///@param Type bool
///@param Default False
extern NSString *const kG8ParamCrunchIncludeNumerals;

/// Don't crunch words with long lower case strings
///@param Type int
///@param Default 4
extern NSString *const kG8ParamCrunchLeaveLcStrings;

/// Don't crunch words with long lower case strings
///@param Type int
///@param Default 4
extern NSString *const kG8ParamCrunchLeaveUcStrings;

/// Crunch words with long repetitions
///@param Type int
///@param Default 3
extern NSString *const kG8ParamCrunchLongRepetitions;

/// As it says
///@param Type int
///@param Default 0
extern NSString *const kG8ParamCrunchDebug;

/// How many non-noise blbs either side?
///@param Type int
///@param Default 1
extern NSString *const kG8ParamFixspNonNoiseLimit;

/// Small if lt xht x this
///@param Type double
///@param Default 0.28
extern NSString *const kG8ParamFixspSmallOutlinesSize;

/// Reward punctuation joins
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditPreferJoinedPunct;

/// What constitutes done for spacing
///@param Type int
///@param Default 1
extern NSString *const kG8ParamFixspDoneMode;

/// Contextual fixspace debug
///@param Type int
///@param Default 0
extern NSString *const kG8ParamDebugFixSpaceLevel;

/// Punct. chs expected WITHIN numbers
///@param Type string
///@param Default .,
extern NSString *const kG8ParamNumericPunctuation;

/// Max allowed deviation of blob top outside of font data
///@param Type int
///@param Default 8
extern NSString *const kG8ParamXHtAcceptanceTolerance;

/// Min change in xht before actually trying it
///@param Type int
///@param Default 8
extern NSString *const kG8ParamXHtMinChange;

/// Debug level for sub & superscript fixer
///@param Type int
///@param Default 0
extern NSString *const kG8ParamSuperscriptDebug;

/// How many times worse certainty does a superscript position glyph need to be for us to try classifying it as a char with a different baseline?
///@param Type double
///@param Default 2.0
extern NSString *const kG8ParamSuperscriptWorseCertainty;

/// What reduction in badness do we think sufficient to choose a superscript over what we'd thought.
/// For example, a value of 0.6 means we want to reduce badness of certainty by at least 40%
///@param Type double
///@param Default 0.97
extern NSString *const kG8ParamSuperscriptBetteredCertainty;

/// A superscript scaled down more than this is unbelievably small.
/// For example, 0.3 means we expect the font size to be no smaller than 30% of the text line font size.
///@param Type double
///@param Default 0.4
extern NSString *const kG8ParamSuperscriptScaledownRatio;

/// Maximum top of a character measured as a multiple of x-height above the baseline for us to reconsider whether it's a subscript.
///@param Type double
///@param Default 0.5
extern NSString *const kG8ParamSubscriptMaxYTop;

/// Minimum bottom of a character measured as a multiple of x-height above the baseline for us to reconsider whether it's a superscript.
///@param Type double
///@param Default 0.3
extern NSString *const kG8ParamSuperscriptMinYBottom;

/// Write block separators in output
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditWriteBlockSeparators;

/// Write repetition char code
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditWriteRepCodes;

/// Write .unlv output file
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditWriteUnlv;

/// Write .txt output file
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditCreateTxt;

/// Write .html hOCR output file
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditCreateHocr;

/// Write .xml ALTO file
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditCreateAlto;

/// Write .page.xml PAGE file
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditCreatePageXml;

/// Create the PAGE file with polygons instead of box values
///@param Type bool
///@param Default True
extern NSString *const kG8ParamPageXmlPolygon;

/// Create the PAGE file on 0=line or 1=word level.
///@param Type int
///@param Default 0
extern NSString *const kG8ParamPageXmlLevel;

/// Write .box file for LSTM training
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditCreateLstmbox;

/// Write .tsv output file
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditCreateTsv;

/// Write WordStr format .box output file
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditCreateWordstrbox;

/// Write .pdf output file
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditCreatePdf;

/// Create PDF with only one invisible text layer
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTextonlyPdf;

/// Set JPEG quality level
///@param Type int
///@param Default 85
extern NSString *const kG8ParamJpgQuality;

/// Specify DPI for input image
///@param Type int
///@param Default 0
extern NSString *const kG8ParamUserDefinedDpi;

/// Specify minimum characters to try during OSD
///@param Type int
///@param Default 50
extern NSString *const kG8ParamMinCharactersToTry;

/// Output char for unidentified blobs
///@param Type string
///@param Default |
extern NSString *const kG8ParamUnrecognisedChar;

/// Suspect marker level
///@param Type int
///@param Default 99
extern NSString *const kG8ParamSuspectLevel;

/// Don't suspect dict wds longer than this
///@param Type int
///@param Default 2
extern NSString *const kG8ParamSuspectShortWords;

/// UNLV keep 1Il chars rejected
///@param Type bool
///@param Default False
extern NSString *const kG8ParamSuspectConstrain1il;

/// Don't touch bad rating limit
///@param Type double
///@param Default 999.9
extern NSString *const kG8ParamSuspectRatingPerCh;

/// Accept good rating limit
///@param Type double
///@param Default -999.9
extern NSString *const kG8ParamSuspectAcceptRating;

/// Only reject tess failures
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditMinimalRejection;

/// Don't reject ANYTHING
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditZeroRejection;

/// Make output have exactly one word per WORD
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditWordForWord;

/// Don't reject ANYTHING AT ALL
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditZeroKelvinRejection;

/// Rejection algorithm
///@param Type int
///@param Default 0
extern NSString *const kG8ParamTesseditRejectMode;

/// Adaption debug
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditRejectionDebug;

/// Contextual 0O O0 flips
///@param Type bool
///@param Default True
extern NSString *const kG8ParamTesseditFlip0o;

/// Aspect ratio dot/hyphen test
///@param Type double
///@param Default 1.5
extern NSString *const kG8ParamTesseditLowerFlipHyphen;

/// Aspect ratio dot/hyphen test
///@param Type double
///@param Default 1.8
extern NSString *const kG8ParamTesseditUpperFlipHyphen;

/// Use DOC dawg in 11l conf. detector
///@param Type bool
///@param Default False
extern NSString *const kG8ParamRejTrustDocDawg;

/// Use dictword test
///@param Type bool
///@param Default False
extern NSString *const kG8ParamRej1ilUseDictWord;

/// Don't double check
///@param Type bool
///@param Default True
extern NSString *const kG8ParamRej1ilTrustPermuterType;

/// Individual rejection control
///@param Type bool
///@param Default True
extern NSString *const kG8ParamRejUseTessAccepted;

/// Individual rejection control
///@param Type bool
///@param Default True
extern NSString *const kG8ParamRejUseTessBlanks;

/// Individual rejection control
///@param Type bool
///@param Default True
extern NSString *const kG8ParamRejUseGoodPerm;

/// Extend permuter check
///@param Type bool
///@param Default False
extern NSString *const kG8ParamRejUseSensibleWd;

/// Extend permuter check
///@param Type bool
///@param Default False
extern NSString *const kG8ParamRejAlphasInNumberPerm;

/// if >this fract
///@param Type double
///@param Default 0.85
extern NSString *const kG8ParamRejWholeOfMostlyRejectWordFract;

/// Rej blbs near image edge limit
///@param Type int
///@param Default 2
extern NSString *const kG8ParamTesseditImageBorder;

/// -?*\075", "Allow NN to unrej
///@param Type string
///@param Default -?*\075
extern NSString *const kG8ParamOkRepeatedChNonAlphanumWds;

/// Il1[]", "Il1 conflict set
///@param Type string
///@param Default Il1[]
extern NSString *const kG8ParamConflictSetIL1;

/// Reject any x-ht lt or eq than this
///@param Type int
///@param Default 8
extern NSString *const kG8ParamMinSaneXHtPixels;

/// Output text with boxes
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditCreateBoxfile;

/// -1 -> All pages, else specific page to process
///@param Type int
///@param Default -1
extern NSString *const kG8ParamTesseditPageNumber;

/// Capture the image from the IPE
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditWriteImages;

/// Run interactively?
///@param Type bool
///@param Default False
extern NSString *const kG8ParamInteractiveDisplayMode;

/// Filename extension
///@param Type string
///@param Default .tif
extern NSString *const kG8ParamFileType;

/// According to dict_word
///@param Type bool
///@param Default True
extern NSString *const kG8ParamTesseditOverridePermuter;

/// List of languages to load with this one
///@param Type string
///@param Default
extern NSString *const kG8ParamTesseditLoadSublangs;

/// In multilingual mode use params model of the primary language
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditUsePrimaryParamsModel;

/// Min acceptable orientation margin
///@param Type double
///@param Default 7.0
extern NSString *const kG8ParamMinOrientationMargin;

/// Debug line finding
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTextordTabfindShowVlines;

/// Use CJK fixed pitch model
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTextordUseCjkFpModel;

/// Allow feature extractors to see the original outline
///@param Type bool
///@param Default False
extern NSString *const kG8ParamPolyAllowDetailedFx;

/// Only initialize with the config file. Useful if the instance is not going to be used for OCR but say only for layout analysis.
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTesseditInitConfigOnly;

#ifndef DISABLED_LEGACY_ENGINE
/// Turn on equation detector
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTextordEquationDetect;
#endif // ndef DISABLED_LEGACY_ENGINE

/// Enable vertical detection
///@param Type bool
///@param Default True
extern NSString *const kG8ParamTextordTabfindVerticalText;

/// Force using vertical text page mode
///@param Type bool
///@param Default False
extern NSString *const kG8ParamTextordTabfindForceVerticalText;

/// Fraction of textlines deemed vertical to use vertical page mode
///@param Type double
///@param Default 0.5
extern NSString *const kG8ParamTextordTabfindVerticalTextRatio;

/// Fraction of height used as a minimum gap for aligned blobs.
///@param Type double
///@param Default 0.75
extern NSString *const kG8ParamTextordTabfindAlignedGapFraction;

/// Run in parallel where possible
///@param Type int
///@param Default 0
extern NSString *const kG8ParamTesseditParallelize;

/// Preserve multiple interword spaces
///@param Type bool
///@param Default False
extern NSString *const kG8ParamPreserveInterwordSpaces;

/// Page separator (default is form feed control character)
///@param Type string
///@param Default 
extern NSString *const kG8ParamPageSeparator;

/// Allows to include alternative symbols choices in the hOCR output.
/// Valid input values are 0, 1 and 2. 0 is the default value.
/// With 1 the alternative symbol choices per timestep are included.
/// With 2 alternative symbol choices are extracted from the CTC process instead of the lattice.
/// The choices are mapped per character.
///@param Type int
///@param Default 0
extern NSString *const kG8ParamLstmChoiceMode;

/// Sets the number of cascading iterations for the Beamsearch in lstm_choice_mode.
/// Note that lstm_choice_mode must be set to a value greater than 0 to produce results.
///@param Type int
///@param Default 5
extern NSString *const kG8ParamLstmChoiceIterations;

/// Sets the rating coefficient for the lstm choices.
/// The smaller the coefficient, the better are the ratings for each choice and less information is lost due to the cut off at 0.
///@param Type double
///@param Default 5.0
extern NSString *const kG8ParamLstmRatingCoefficient;

/// Detect music staff and remove intersecting components
///@param Type bool
///@param Default False
extern NSString *const kG8ParamPagesegApplyMusicMask;

@end

#endif
