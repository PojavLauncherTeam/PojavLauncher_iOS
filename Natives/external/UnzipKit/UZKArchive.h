//
//  UZKArchive.h
//  UnzipKit
//
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "UZKFileInfo.h"

/**
 *  Defines the various error codes that the listing and extraction methods return.
 *  These are returned in NSError's [code]([NSError code]) field.
 */
typedef NS_ENUM(NSInteger, UZKErrorCode) {
    
    /**
     *  An error from zlib reading or writing the file (UNZ_ERRNO/ZIP_ERRNO)
     */
    UZKErrorCodeZLibError = -1,
    
    /**
     *  An error with a parameter, usually the file name (UNZ_PARAMERROR/ZIP_PARAMERROR)
     */
    UZKErrorCodeParameterError = -102,
    
    /**
     *  The Zip file appears to be corrupted, or invalid (UNZ_BADZIPFILE/ZIP_BADZIPFILE)
     */
    UZKErrorCodeBadZipFile = -103,
    
    /**
     *  An error internal to MiniZip (UNZ_INTERNALERROR/ZIP_INTERNALERROR)
     */
    UZKErrorCodeInternalError = -104,
    
    /**
     *  The decompressed file's CRC doesn't match the original file's CRC (UNZ_CRCERROR)
     */
    UZKErrorCodeCRCError = -105,
    
    /**
     *  Failure to find/open the archive
     */
    UZKErrorCodeArchiveNotFound = 101,
    
    /**
     *  Error reading or advancing through the archive
     */
    UZKErrorCodeFileNavigationError = 102,
    
    /**
     *  Error finding a file in the archive
     */
    UZKErrorCodeFileNotFoundInArchive = 103,
    
    /**
     *  Error writing an extracted file to disk
     */
    UZKErrorCodeOutputError = 104,
    
    /**
     *  The destination directory is a file. Not used anymore
     */
    UZKErrorCodeOutputErrorPathIsAFile = 105,
    
    /**
     *  Password given doesn't decrypt the archive
     */
    UZKErrorCodeInvalidPassword = 106,
    
    /**
     *  Error reading a file in the archive
     */
    UZKErrorCodeFileRead = 107,
    
    /**
     *  Error opening a file in the archive for writing
     */
    UZKErrorCodeFileOpenForWrite = 108,
    
    /**
     *  Error writing a file in the archive
     */
    UZKErrorCodeFileWrite = 109,
    
    /**
     *  Error closing the file in the archive
     */
    UZKErrorCodeFileCloseWriting = 110,
    
    /**
     *  Error deleting a file in the archive
     */
    UZKErrorCodeDeleteFile = 111,
    
    /**
     *  Tried to read before all writes have completed, or vise-versa
     */
    UZKErrorCodeMixedModeAccess = 112,
    
    /**
     *  Error reading the global comment of the archive
     */
    UZKErrorCodeReadComment = 113,
    
    /**
     *  The CRC given up front doesn't match the calculated CRC
     */
    UZKErrorCodePreCRCMismatch = 114,
    
    /**
     *  The zip is compressed using Deflate64 (compression method 9), which isn't supported
     */
    UZKErrorCodeDeflate64 = 115,
    
    /**
     *  User cancelled the operation
     */
    UZKErrorCodeUserCancelled = 116,
};


typedef NSString *const UZKProgressInfoKey;

/**
 *  Defines the keys passed in `-[NSProgress userInfo]` for certain methods
 */
static UZKProgressInfoKey _Nonnull
/**
 *  For `extractFilesTo:overwrite:error:`, this key contains an instance of URKFileInfo with the file currently being extracted
 */
UZKProgressInfoKeyFileInfoExtracting = @"UZKProgressInfoKeyFileInfoExtracting";

NS_ASSUME_NONNULL_BEGIN

extern NSString *UZKErrorDomain;

@interface UZKArchive : NSObject
// Minimum of iOS 9, macOS 10.11 SDKs
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED > 90000) || (defined(MAC_OS_X_VERSION_MIN_REQUIRED) && MAC_OS_X_VERSION_MIN_REQUIRED > 101100)
<NSProgressReporting>
#endif

/**
 *  The URL of the archive. Returns nil if the URL becomes unreachable
 */
@property(weak, nonatomic, readonly, nullable) NSURL *fileURL;

/**
 *  The filename of the archive. Returns nil if the archive file becomes unreachable
 */
@property(weak, nonatomic, readonly, nullable)  NSString *filename;

/**
 *  The password of the archive
 */
@property(strong, nullable) NSString *password;

/**
 *  The global comment inside the archive
 *
 *  Comments are written in UTF-8, and read in UTF-8 and Windows/CP-1252, falling back to defaultCStringEncoding
 */
@property(retain, atomic, nullable) NSString *comment;

/**
 *  Can be used for progress reporting, but it's not necessary. You can also use
 *  implicit progress reporting. If you don't use it, one will still be created,
 *  which will become a child progress of whichever one is the current NSProgress
 *  instance.
 *
 *  To use this, assign it before beginning an operation that reports progress. Once
 *  the method you're calling has a reference to it, it will nil it out. Please check
 *  for nil before assigning it to avoid concurrency conflicts.
 */
@property(nullable, strong) NSProgress *progress;


/**
 *  DEPRECATED: Creates and returns an archive at the given path
 *
 *  @param filePath A path to the archive file
 *
 *  @return Returns a UZKArchive object, or nil if the path isn't reachable
 */
+ (nullable instancetype)zipArchiveAtPath:(NSString *)filePath __deprecated_msg("Use -initWithPath:error: instead");

/**
 *  DEPRECATED: Creates and returns an archive at the given URL
 *
 *  @param fileURL The URL of the archive file
 *
 *  @return Returns a UZKArchive object, or nil if the URL isn't reachable
 */
+ (nullable instancetype)zipArchiveAtURL:(NSURL *)fileURL __deprecated_msg("Use -initWithURL:error: instead");

/**
 *  DEPRECATED: Creates and returns an archive at the given path, with a given password
 *
 *  @param filePath A path to the archive file
 *  @param password The password of the given archive
 *
 *  @return Returns a UZKArchive object, or nil if the path isn't reachable
 */
+ (nullable instancetype)zipArchiveAtPath:(NSString *)filePath password:(nullable NSString *)password __deprecated_msg("Use -initWithPath:password:error: instead");

/**
 *  DEPRECATED: Creates and returns an archive at the given URL, with a given password
 *
 *  @param fileURL  The URL of the archive file
 *  @param password The password of the given archive
 *
 *  @return Returns a UZKArchive object, or nil if the URL isn't reachable
 */
+ (nullable instancetype)zipArchiveAtURL:(NSURL *)fileURL password:(nullable NSString *)password __deprecated_msg("Use -initWithURL:password:error: instead");;


/**
 *  Creates and returns an archive at the given path
 *
 *  @param filePath A path to the archive file
 *  @param error    Returns an error code if the object can't be initialized
 *
 *  @return Returns a UZKArchive object, or nil if the path isn't reachable
 */
- (nullable instancetype)initWithPath:(NSString *)filePath error:(NSError **)error;

/**
 *  Creates and returns an archive at the given URL
 *
 *  @param fileURL The URL of the archive file
 *  @param error    Returns an error code if the object can't be initialized
 *
 *  @return Returns a UZKArchive object, or nil if the URL isn't reachable
 */
- (nullable instancetype)initWithURL:(NSURL *)fileURL error:(NSError **)error;

/**
 *  Creates and returns an archive at the given path, with a given password
 *
 *  @param filePath A path to the archive file
 *  @param password The password of the given archive
 *  @param error    Returns an error code if the object can't be initialized
 *
 *  @return Returns a UZKArchive object, or nil if the path isn't reachable
 */
- (nullable instancetype)initWithPath:(NSString *)filePath password:(nullable NSString *)password error:(NSError **)error;

/**
 *  Creates and returns an archive at the given URL, with a given password
 *
 *  @param fileURL  The URL of the archive file
 *  @param password The password of the given archive
 *  @param error    Returns an error code if the object can't be initialized
 *
 *  @return Returns a UZKArchive object, or nil if the URL isn't reachable
 */
- (nullable instancetype)initWithURL:(NSURL *)fileURL password:(nullable NSString *)password error:(NSError **)error;



#pragma mark - Read Methods


/**
 *  Determines whether a file is a Zip file by reading the header
 *
 *  @param filePath Path to the file being checked
 *
 *  @return YES if the file exists and contains a signature indicating it is a Zip file
 */
+ (BOOL)pathIsAZip:(NSString *)filePath;

/**
 *  Determines whether a file is a Zip file by reading the header
 *
 *  @param fileURL URL of the file being checked
 *
 *  @return YES if the file exists and contains a signature indicating it is a Zip file
 */
+ (BOOL)urlIsAZip:(NSURL *)fileURL;


/**
 *  Lists the names of the files in the archive
 *
 *  @param error Contains an NSError object when there was an error reading the archive
 *
 *  @return Returns a list of NSString containing the paths within the archive's contents, or nil if an error was encountered
 */
- (nullable NSArray<NSString*> *)listFilenames:(NSError **)error;

/**
 *  Lists the various attributes of each file in the archive
 *
 *  @param error Contains an NSError object when there was an error reading the archive
 *
 *  @return Returns a list of UZKFileInfo objects, which contain metadata about the archive's files, or nil if an error was encountered
 */
- (nullable NSArray<UZKFileInfo*> *)listFileInfo:(NSError **)error;

/**
 *  Writes all files in the archive to the given path. Supports NSProgress for progress reporting, which also
 *  allows cancellation in the middle of extraction. Use the progress property (as explained in the README) to
 *  retrieve more detailed information, such as the current file being extracted, number of files extracted,
 *  and the URKFileInfo instance being extracted
 *
 *  @param destinationDirectory  The destination path of the unarchived files
 *  @param overwrite             YES to overwrite files in the destination directory, NO otherwise
 *
 *  @param error     Contains an NSError object when there was an error reading the archive
 *
 *  @return YES on successful extraction, NO if an error was encountered
 */
- (BOOL)extractFilesTo:(NSString *)destinationDirectory
             overwrite:(BOOL)overwrite
                 error:(NSError **)error;

/**
 *  **DEPRECATED:** Writes all files in the archive to the given path
 *
 *  @param destinationDirectory  The destination path of the unarchived files
 *  @param overwrite             YES to overwrite files in the destination directory, NO otherwise
 *  @param progress              Called every so often to report the progress of the extraction
 *
 *       - *currentFile*                The info about the file that's being extracted
 *       - *percentArchiveDecompressed* The percentage of the archive that has been decompressed
 *
 *  @param error     Contains an NSError object when there was an error reading the archive
 *
 *  @return YES on successful extraction, NO if an error was encountered
 */
- (BOOL)extractFilesTo:(NSString *)destinationDirectory
             overwrite:(BOOL)overwrite
              progress:(nullable void (^)(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed))progress
                 error:(NSError **)error __deprecated_msg("Use -extractFilesTo:overwrite:error: instead, and if using the progress block, replace with NSProgress as described in the README");

/**
 *  Unarchive a single file from the archive into memory. Supports NSProgress for progress reporting, which also
 *  allows cancellation in the middle of extraction
 *
 *  @param fileInfo The info of the file within the archive to be expanded. Only the filename property is used
 *  @param error    Contains an NSError object when there was an error reading the archive
 *
 *  @return An NSData object containing the bytes of the file, or nil if an error was encountered
 */
- (nullable NSData *)extractData:(UZKFileInfo *)fileInfo
                           error:(NSError **)error;

/**
 *  **DEPRECATED:** Unarchive a single file from the archive into memory
 *
 *  @param fileInfo The info of the file within the archive to be expanded. Only the filename property is used
 *  @param progress Called every so often to report the progress of the extraction
 *
 *       - *percentDecompressed* The percentage of the archive that has been decompressed
 *
 *  @param error    Contains an NSError object when there was an error reading the archive
 *
 *  @return An NSData object containing the bytes of the file, or nil if an error was encountered
 */
- (nullable NSData *)extractData:(UZKFileInfo *)fileInfo
                        progress:(nullable void (^)(CGFloat percentDecompressed))progress
                           error:(NSError **)error __deprecated_msg("Use -extractData:error: instead, and if using the progress block, replace with NSProgress as described in the README");

/**
 *  Unarchive a single file from the archive into memory. Supports NSProgress for progress reporting, which also
 *  allows cancellation in the middle of extraction
 *
 *  @param filePath The path of the file within the archive to be expanded
 *  @param error    Contains an NSError object when there was an error reading the archive
 *
 *  @return An NSData object containing the bytes of the file, or nil if an error was encountered
 */
- (nullable NSData *)extractDataFromFile:(NSString *)filePath
                                   error:(NSError **)error;

/**
 *  **DEPRECATED:** Unarchive a single file from the archive into memory
 *
 *  @param filePath The path of the file within the archive to be expanded
 *  @param progress Called every so often to report the progress of the extraction
 *
 *       - *percentDecompressed* The percentage of the file that has been decompressed
 *
 *  @param error    Contains an NSError object when there was an error reading the archive
 *
 *  @return An NSData object containing the bytes of the file, or nil if an error was encountered
 */
- (nullable NSData *)extractDataFromFile:(NSString *)filePath
                                progress:(nullable void (^)(CGFloat percentDecompressed))progress
                                   error:(NSError **)error __deprecated_msg("Use -extractDataFromFile:error: instead, and if using the progress block, replace with NSProgress as described in the README");

/**
 *  Loops through each file in the archive into memory, allowing you to perform an action
 *  using its info. Supports NSProgress for progress reporting, which also
 *  allows cancellation in the middle of the operation
 *
 *  @param action The action to perform using the data
 *
 *       - *fileInfo* The metadata of the file within the archive
 *       - *stop*     Set to YES to stop reading the archive
 *
 *  @param error  Contains an error if any was returned
 *
 *  @return YES if no errors were encountered, NO otherwise
 */
- (BOOL)performOnFilesInArchive:(void(^)(UZKFileInfo *fileInfo, BOOL *stop))action
                          error:(NSError **)error;

/**
 *  Extracts each file in the archive into memory, allowing you to perform an action
 *  on it. Supports NSProgress for progress reporting, which also allows cancellation
 *  in the middle of the operation
 *
 *  @param action The action to perform using the data
 *
 *       - *fileInfo* The metadata of the file within the archive
 *       - *fileData* The full data of the file in the archive
 *       - *stop*     Set to YES to stop reading the archive
 *
 *  @param error  Contains an error if any was returned
 *
 *  @return YES if no errors were encountered, NO otherwise
 */
- (BOOL)performOnDataInArchive:(void(^)(UZKFileInfo *fileInfo, NSData *fileData, BOOL *stop))action
                         error:(NSError **)error;

/**
 *  Unarchive a single file from the archive into memory. Supports NSProgress for progress reporting, which also
 *  allows cancellation in the middle of extraction
 *
 *  @param filePath   The path of the file within the archive to be expanded
 *  @param error      Contains an NSError object when there was an error reading the archive
 *  @param action     The block to run for each chunk of data, each of size <= bufferSize
 *
 *       - *dataChunk*           The data read from the archived file. Read bytes and length to write the data
 *       - *percentDecompressed* The percentage of the file that has been decompressed
 *
 *  @return YES if all data was read successfully, NO if an error was encountered
 */
- (BOOL)extractBufferedDataFromFile:(NSString *)filePath
                              error:(NSError **)error
                             action:(void(^)(NSData *dataChunk, CGFloat percentDecompressed))action;

/**
 *  YES if archive protected with a password, NO otherwise
 */
- (BOOL)isPasswordProtected;

/**
 *  Tests whether the provided password unlocks the archive
 *
 *  @return YES if correct password or archive is not password protected, NO if password is wrong
 */
- (BOOL)validatePassword;

/**
 Extract each file in the archive, checking whether the data matches the CRC checksum
 stored at the time it was written
 
 @return YES if the data is all correct, false if any check failed
 */
- (BOOL)checkDataIntegrity;

/**
 Extract a particular file, to determine if its data matches the CRC
 checksum stored at the time it written
 
 @param filePath The file in the archive to check
 
 @return YES if the data is correct, false if any check failed
 */
- (BOOL)checkDataIntegrityOfFile:(NSString *)filePath;



#pragma mark - Write Methods


/**
 *  Writes the data to the zip file, overwriting it if a file of that name already exists
 *  in the archive. Supports NSProgress for progress reporting, which DOES NOT allow cancellation
 *  in the middle of writing
 *
 *  @param data     Data to write into the archive
 *  @param filePath The full path to the target file in the archive
 *  @param error    Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
            error:(NSError **)error;

/**
 *  **DEPRECATED:** Writes the data to the zip file, overwriting it if a file of that name already exists in the
 *  archive
 *
 *  @param data     Data to write into the archive
 *  @param filePath The full path to the target file in the archive
 *  @param progress Called every so often to report the progress of the compression
 *
 *       - *percentCompressed* The percentage of the file that has been compressed
 *
 *  @param error    Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         progress:(nullable void (^)(CGFloat percentCompressed))progress
            error:(NSError **)error __deprecated_msg("Use -writeData:filePath:error: instead, and if using the progress block, replace with NSProgress as described in the README");

/**
 *  Writes the data to the zip file, overwriting it if a file of that name already exists in the archive
 *
 *  @param data     Data to write into the archive
 *  @param filePath The full path to the target file in the archive
 *  @param fileDate The timestamp of the file in the archive. Uses the current time if nil
 *  @param error    Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(nullable NSDate *)fileDate
            error:(NSError **)error;

/**
 *  **DEPRECATED:** Writes the data to the zip file, overwriting it if a file of that name already exists in the archive
 *
 *  @param data     Data to write into the archive
 *  @param filePath The full path to the target file in the archive
 *  @param fileDate The timestamp of the file in the archive. Uses the current time if nil
 *  @param progress Called every so often to report the progress of the compression
 *
 *       - *percentCompressed* The percentage of the file that has been compressed
 *
 *  @param error     Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(nullable NSDate *)fileDate
         progress:(nullable void (^)(CGFloat percentCompressed))progress
            error:(NSError **)error __deprecated_msg("Use -writeData:filePath:fileDate:error: instead, and if using the progress block, replace with NSProgress as described in the README");

/**
 *  Writes the data to the zip file, overwriting it if a file of that name already exists in the archive
 *
 *  @param data     Data to write into the archive
 *  @param filePath The full path to the target file in the archive
 *  @param fileDate The timestamp of the file in the archive. Uses the current time if nil
 *  @param method   The UZKCompressionMethod to use (Default, None, Fastest, Best)
 *  @param password Override the password associated with the archive (not recommended)
 *  @param error    Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(nullable NSDate *)fileDate
compressionMethod:(UZKCompressionMethod)method
         password:(nullable NSString *)password
            error:(NSError **)error;

/**
 *  **DEPRECATED:** Writes the data to the zip file, overwriting it if a file of that name already exists in the archive
 *
 *  @param data     Data to write into the archive
 *  @param filePath The full path to the target file in the archive
 *  @param fileDate The timestamp of the file in the archive. Uses the current time if nil
 *  @param method   The UZKCompressionMethod to use (Default, None, Fastest, Best)
 *  @param password Override the password associated with the archive (not recommended)
 *  @param progress Called every so often to report the progress of the compression
 *
 *       - *percentCompressed* The percentage of the file that has been compressed
 *
 *  @param error     Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(nullable NSDate *)fileDate
compressionMethod:(UZKCompressionMethod)method
         password:(nullable NSString *)password
         progress:(nullable void (^)(CGFloat percentCompressed))progress
            error:(NSError **)error __deprecated_msg("Use -writeData:filePath:fileDate:compressionMethod:password:error: instead, and if using the progress block, replace with NSProgress as described in the README");

/**
 *  Writes the data to the zip file, overwriting only if specified with the overwrite flag. Overwriting
 *  presents a tradeoff: the whole archive needs to be copied (minus the file to be overwritten) before
 *  the write begins. For a large archive, this can be slow. On the other hand, when not overwriting,
 *  the size of the archive will grow each time the file is written.
 *
 *  @param data      Data to write into the archive
 *  @param filePath  The full path to the target file in the archive
 *  @param fileDate  The timestamp of the file in the archive. Uses the current time if nil
 *  @param method    The UZKCompressionMethod to use (Default, None, Fastest, Best)
 *  @param password  Override the password associated with the archive (not recommended)
 *  @param overwrite If YES, and the file exists, delete it before writing. If NO, append
 *                   the data into the archive without removing it first (legacy Objective-Zip
 *                   behavior)
 *  @param error     Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(nullable NSDate *)fileDate
compressionMethod:(UZKCompressionMethod)method
         password:(nullable NSString *)password
        overwrite:(BOOL)overwrite
            error:(NSError **)error;

/**
 *  Writes the data to the zip file, overwriting only if specified with the overwrite flag. Overwriting
 *  presents a tradeoff: the whole archive needs to be copied (minus the file to be overwritten) before
 *  the write begins. For a large archive, this can be slow. On the other hand, when not overwriting,
 *  the size of the archive will grow each time the file is written.
 *
 *  @param data        Data to write into the archive
 *  @param filePath    The full path to the target file in the archive
 *  @param fileDate    The timestamp of the file in the archive. Uses the current time if nil
 *  @param permissions The desired POSIX permissions of the file in the archive
 *  @param method      The UZKCompressionMethod to use (Default, None, Fastest, Best)
 *  @param password    Override the password associated with the archive (not recommended)
 *  @param overwrite   If YES, and the file exists, delete it before writing. If NO, append
 *                     the data into the archive without removing it first (legacy Objective-Zip
 *                     behavior)
 *  @param error       Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(nullable NSDate *)fileDate
 posixPermissions:(short)permissions
compressionMethod:(UZKCompressionMethod)method
         password:(nullable NSString *)password
        overwrite:(BOOL)overwrite
            error:(NSError **)error;

/**
 *  **DEPRECATED:** Writes the data to the zip file, overwriting only if specified with the overwrite flag. Overwriting
 *  presents a tradeoff: the whole archive needs to be copied (minus the file to be overwritten) before
 *  the write begins. For a large archive, this can be slow. On the other hand, when not overwriting,
 *  the size of the archive will grow each time the file is written.
 *
 *  @param data      Data to write into the archive
 *  @param filePath  The full path to the target file in the archive
 *  @param fileDate  The timestamp of the file in the archive. Uses the current time if nil
 *  @param method    The UZKCompressionMethod to use (Default, None, Fastest, Best)
 *  @param password  Override the password associated with the archive (not recommended)
 *  @param overwrite If YES, and the file exists, delete it before writing. If NO, append
 *                   the data into the archive without removing it first (legacy Objective-Zip
 *                   behavior)
 *  @param progress  Called every so often to report the progress of the compression
 *
 *       - *percentCompressed* The percentage of the file that has been compressed
 *
 *  @param error     Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(nullable NSDate *)fileDate
compressionMethod:(UZKCompressionMethod)method
         password:(nullable NSString *)password
        overwrite:(BOOL)overwrite
         progress:(nullable void (^)(CGFloat percentCompressed))progress
            error:(NSError **)error __deprecated_msg("Use -writeData:filePath:fileDate:compressionMethod:password:overwrite:error: instead, and if using the progress block, replace with NSProgress as described in the README");

/**
 *  **DEPRECATED:** Writes the data to the zip file, overwriting only if specified with the overwrite flag. Overwriting
 *  presents a tradeoff: the whole archive needs to be copied (minus the file to be overwritten) before
 *  the write begins. For a large archive, this can be slow. On the other hand, when not overwriting,
 *  the size of the archive will grow each time the file is written.
 *
 *  @param data        Data to write into the archive
 *  @param filePath    The full path to the target file in the archive
 *  @param fileDate    The timestamp of the file in the archive. Uses the current time if nil
 *  @param permissions The desired POSIX permissions of the file in the archive
 *  @param method      The UZKCompressionMethod to use (Default, None, Fastest, Best)
 *  @param password    Override the password associated with the archive (not recommended)
 *  @param overwrite   If YES, and the file exists, delete it before writing. If NO, append
 *                     the data into the archive without removing it first (legacy Objective-Zip
 *                     behavior)
 *  @param progress    Called every so often to report the progress of the compression
 *
 *       - *percentCompressed* The percentage of the file that has been compressed
 *
 *  @param error     Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeData:(NSData *)data
         filePath:(NSString *)filePath
         fileDate:(nullable NSDate *)fileDate
 posixPermissions:(short)permissions
compressionMethod:(UZKCompressionMethod)method
         password:(nullable NSString *)password
        overwrite:(BOOL)overwrite
         progress:(nullable void (^)(CGFloat percentCompressed))progress
            error:(NSError **)error __deprecated_msg("Use -writeData:filePath:fileDate:permissions:compressionMethod:password:overwrite:error: instead, and if using the progress block, replace with NSProgress as described in the README");

/**
 *  Writes data to the zip file in pieces, allowing you to stream the write, so the entire contents
 *  don't need to reside in memory at once. It overwrites an existing file with the same name.
 *
 *  @param filePath The full path to the target file in the archive
 *  @param error    Contains an NSError object when there was an error writing to the archive
 *  @param action   Contains your code to loop through the source bytes and write them to the
 *                  archive. Each time a chunk of data is ready to be written, call writeData,
 *                  passing in a pointer to the bytes and their length. Return YES if successful,
 *                  or NO on error (in which case, you should assign the actionError parameter
 *
 *       - *writeData*   Call this block to write some bytes into the archive. It returns NO if the
 *                       write failed. If this happens, you should return from the action block, and
 *                       handle the NSError returned into the error reference
 *       - *actionError* Assign to an NSError instance before returning NO
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeIntoBuffer:(NSString *)filePath
                  error:(NSError **)error
                  block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError **actionError))action;

/**
 *  Writes data to the zip file in pieces, allowing you to stream the write, so the entire contents
 *  don't need to reside in memory at once. It overwrites an existing file with the same name.
 *
 *  @param filePath The full path to the target file in the archive
 *  @param fileDate The timestamp of the file in the archive. Uses the current time if nil
 *  @param error    Contains an NSError object when there was an error writing to the archive
 *  @param action   Contains your code to loop through the source bytes and write them to the
 *                  archive. Each time a chunk of data is ready to be written, call writeData,
 *                  passing in a pointer to the bytes and their length. Return YES if successful,
 *                  or NO on error (in which case, you should assign the actionError parameter
 *
 *       - *writeData*   Call this block to write some bytes into the archive. It returns NO if the
 *                       write failed. If this happens, you should return from the action block, and
 *                       handle the NSError returned into the error reference
 *       - *actionError* Assign to an NSError instance before returning NO
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeIntoBuffer:(NSString *)filePath
               fileDate:(nullable NSDate *)fileDate
                  error:(NSError **)error
                  block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError **actionError))action;

/**
 *  Writes data to the zip file in pieces, allowing you to stream the write, so the entire contents
 *  don't need to reside in memory at once. It overwrites an existing file with the same name.
 *
 *  @param filePath The full path to the target file in the archive
 *  @param fileDate The timestamp of the file in the archive. Uses the current time if nil
 *  @param method   The UZKCompressionMethod to use (Default, None, Fastest, Best)
 *  @param error    Contains an NSError object when there was an error writing to the archive
 *  @param action   Contains your code to loop through the source bytes and write them to the
 *                  archive. Each time a chunk of data is ready to be written, call writeData,
 *                  passing in a pointer to the bytes and their length. Return YES if successful,
 *                  or NO on error (in which case, you should assign the actionError parameter
 *
 *       - *writeData*   Call this block to write some bytes into the archive. It returns NO if the
 *                       write failed. If this happens, you should return from the action block, and
 *                       handle the NSError returned into the error reference
 *       - *actionError* Assign to an NSError instance before returning NO
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeIntoBuffer:(NSString *)filePath
               fileDate:(nullable NSDate *)fileDate
      compressionMethod:(UZKCompressionMethod)method
                  error:(NSError **)error
                  block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError **actionError))action;

/**
 *  Writes data to the zip file in pieces, allowing you to stream the write, so the entire contents
 *  don't need to reside in memory at once. It overwrites an existing file with the same name, only if
 *  specified with the overwrite flag. Overwriting presents a tradeoff: the whole archive needs to be
 *  copied (minus the file to be overwritten) before the write begins. For a large archive, this can
 *  be slow. On the other hand, when not overwriting, the size of the archive will grow each time
 *  the file is written.
 *
 *  @param filePath  The full path to the target file in the archive
 *  @param fileDate  The timestamp of the file in the archive. Uses the current time if nil
 *  @param method    The UZKCompressionMethod to use (Default, None, Fastest, Best)
 *  @param overwrite If YES, and the file exists, delete it before writing. If NO, append
 *                   the data into the archive without removing it first (legacy Objective-Zip
 *                   behavior)
 *  @param error     Contains an NSError object when there was an error writing to the archive
 *  @param action    Contains your code to loop through the source bytes and write them to the
 *                   archive. Each time a chunk of data is ready to be written, call writeData,
 *                   passing in a pointer to the bytes and their length. Return YES if successful,
 *                   or NO on error (in which case, you should assign the actionError parameter
 *
 *       - *writeData*   Call this block to write some bytes into the archive. It returns NO if the
 *                       write failed. If this happens, you should return from the action block, and
 *                       handle the NSError returned into the error reference
 *       - *actionError* Assign to an NSError instance before returning NO
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeIntoBuffer:(NSString *)filePath
               fileDate:(nullable NSDate *)fileDate
      compressionMethod:(UZKCompressionMethod)method
              overwrite:(BOOL)overwrite
                  error:(NSError **)error
                  block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError **actionError))action;

/**
 *  Writes data to the zip file in pieces, allowing you to stream the write, so the entire contents
 *  don't need to reside in memory at once. It overwrites an existing file with the same name, only if
 *  specified with the overwrite flag. Overwriting presents a tradeoff: the whole archive needs to be
 *  copied (minus the file to be overwritten) before the write begins. For a large archive, this can
 *  be slow. On the other hand, when not overwriting, the size of the archive will grow each time
 *  the file is written.
 *
 *  @param filePath  The full path to the target file in the archive
 *  @param fileDate  The timestamp of the file in the archive. Uses the current time if nil
 *  @param method    The UZKCompressionMethod to use (Default, None, Fastest, Best)
 *  @param overwrite If YES, and the file exists, delete it before writing. If NO, append
 *                   the data into the archive without removing it first (legacy Objective-Zip
 *                   behavior)
 *  @param preCRC    The CRC-32 for the data being sent. Only necessary if encrypting the file.
                     Pass 0 otherwise
 *  @param error     Contains an NSError object when there was an error writing to the archive
 *  @param action    Contains your code to loop through the source bytes and write them to the
 *                   archive. Each time a chunk of data is ready to be written, call writeData,
 *                   passing in a pointer to the bytes and their length. Return YES if successful,
 *                   or NO on error (in which case, you should assign the actionError parameter
 *
 *       - *writeData*   Call this block to write some bytes into the archive. It returns NO if the
 *                       write failed. If this happens, you should return from the action block, and
 *                       handle the NSError returned into the error reference
 *       - *actionError* Assign to an NSError instance before returning NO
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeIntoBuffer:(NSString *)filePath
               fileDate:(nullable NSDate *)fileDate
      compressionMethod:(UZKCompressionMethod)method
              overwrite:(BOOL)overwrite
                    CRC:(unsigned long)preCRC
                  error:(NSError **)error
                  block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError **actionError))action;

/**
 *  Writes data to the zip file in pieces, allowing you to stream the write, so the entire contents
 *  don't need to reside in memory at once. It overwrites an existing file with the same name, only if
 *  specified with the overwrite flag. Overwriting presents a tradeoff: the whole archive needs to be
 *  copied (minus the file to be overwritten) before the write begins. For a large archive, this can
 *  be slow. On the other hand, when not overwriting, the size of the archive will grow each time
 *  the file is written.
 *
 *  @param filePath  The full path to the target file in the archive
 *  @param fileDate  The timestamp of the file in the archive. Uses the current time if nil
 *  @param method    The UZKCompressionMethod to use (Default, None, Fastest, Best)
 *  @param overwrite If YES, and the file exists, delete it before writing. If NO, append
 *                   the data into the archive without removing it first (legacy Objective-Zip
 *                   behavior)
 *  @param preCRC    The CRC-32 for the data being sent. Only necessary if encrypting the file.
 *                   Pass 0 otherwise
 *  @param password  Override the password associated with the archive (not recommended)
 *  @param error     Contains an NSError object when there was an error writing to the archive
 *  @param action    Contains your code to loop through the source bytes and write them to the
 *                   archive. Each time a chunk of data is ready to be written, call writeData,
 *                   passing in a pointer to the bytes and their length. Return YES if successful,
 *                   or NO on error (in which case, you should assign the actionError parameter
 *
 *       - *writeData*   Call this block to write some bytes into the archive. It returns NO if the
 *                       write failed. If this happens, you should return from the action block, and
 *                       handle the NSError returned into the error reference
 *       - *actionError* Assign to an NSError instance before returning NO
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeIntoBuffer:(NSString *)filePath
               fileDate:(nullable NSDate *)fileDate
      compressionMethod:(UZKCompressionMethod)method
              overwrite:(BOOL)overwrite
                    CRC:(unsigned long)preCRC
               password:(nullable NSString *)password
                  error:(NSError **)error
                  block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError **actionError))action;


/**
 *  Writes data to the zip file in pieces, allowing you to stream the write, so the entire contents
 *  don't need to reside in memory at once. It overwrites an existing file with the same name, only if
 *  specified with the overwrite flag. Overwriting presents a tradeoff: the whole archive needs to be
 *  copied (minus the file to be overwritten) before the write begins. For a large archive, this can
 *  be slow. On the other hand, when not overwriting, the size of the archive will grow each time
 *  the file is written.
 *
 *  @param filePath    The full path to the target file in the archive
 *  @param fileDate    The timestamp of the file in the archive. Uses the current time if nil
 *  @param permissions The desired POSIX permissions of the file in the archive
 *  @param method      The UZKCompressionMethod to use (Default, None, Fastest, Best)
 *  @param overwrite   If YES, and the file exists, delete it before writing. If NO, append
 *                     the data into the archive without removing it first (legacy Objective-Zip
 *                     behavior)
 *  @param preCRC      The CRC-32 for the data being sent. Only necessary if encrypting the file.
 *                     Pass 0 otherwise
 *  @param password    Override the password associated with the archive (not recommended)
 *  @param error       Contains an NSError object when there was an error writing to the archive
 *  @param action      Contains your code to loop through the source bytes and write them to the
 *                     archive. Each time a chunk of data is ready to be written, call writeData,
 *                     passing in a pointer to the bytes and their length. Return YES if successful,
 *                     or NO on error (in which case, you should assign the actionError parameter
 *
 *       - *writeData*   Call this block to write some bytes into the archive. It returns NO if the
 *                       write failed. If this happens, you should return from the action block, and
 *                       handle the NSError returned into the error reference
 *       - *actionError* Assign to an NSError instance before returning NO
 *
 *  @return YES if successful, NO on error
 */
- (BOOL)writeIntoBuffer:(NSString *)filePath
               fileDate:(nullable NSDate *)fileDate
       posixPermissions:(short)permissions
      compressionMethod:(UZKCompressionMethod)method
              overwrite:(BOOL)overwrite
                    CRC:(unsigned long)preCRC
               password:(nullable NSString *)password
                  error:(NSError **)error
                  block:(BOOL(^)(BOOL(^writeData)(const void *bytes, unsigned int length), NSError **actionError))action;

/**
 *  Removes the given file from the archive
 *
 *  @param filePath The file in the archive you wish to delete
 *  @param error    Contains an NSError object when there was an error writing to the archive
 *
 *  @return YES if the file was successfully deleted, NO otherwise
 */
- (BOOL)deleteFile:(NSString *)filePath error:(NSError **)error;


@end
NS_ASSUME_NONNULL_END
