{stdenv, fetchFromGitHub, perl, yasm
, vp8DecoderSupport ? true # VP8 decoder
, vp8EncoderSupport ? true # VP8 encoder
, vp9DecoderSupport ? true # VP9 decoder
, vp9EncoderSupport ? true # VP9 encoder
, extraWarningsSupport ? false # emit non-fatal warnings
, werrorSupport ? false # treat warnings as errors (not available with all compilers)
, debugSupport ? false # debug mode
, gprofSupport ? false # gprof profiling instrumentation
, gcovSupport ? false # gcov coverage instrumentation
, sizeLimitSupport ? true # limit max size to allow in the decoder
, optimizationsSupport ? true # compiler optimization flags
, runtimeCpuDetectSupport ? true # detect cpu capabilities at runtime
, thumbSupport ? false # build arm assembly in thumb mode
, examplesSupport ? true # build examples (vpxdec & vpxenc are part of examples)
, debugLibsSupport ? false # include debug version of each library
, postprocSupport ? true # postprocessing
, multithreadSupport ? true # multithreaded decoding & encoding
, internalStatsSupport ? false # output of encoder internal stats for debug, if supported (encoders)
, spatialResamplingSupport ? true # spatial sampling (scaling)
, realtimeOnlySupport ? false # build for real-time encoding
, ontheflyBitpackingSupport ? false # on-the-fly bitpacking in real-time encoding
, errorConcealmentSupport ? false # decoder conceals losses
, smallSupport ? false # favor smaller binary over speed
, postprocVisualizerSupport ? false # macro block/block level visualizers
, unitTestsSupport ? false, curl ? null, coreutils ? null # unit tests
, webmIOSupport ? true # input from and output to webm container
, libyuvSupport ? true # libyuv
, decodePerfTestsSupport ? false # build decoder perf tests with unit tests
, encodePerfTestsSupport ? false # build encoder perf tests with unit tests
, multiResEncodingSupport ? false # multiple-resolution encoding
, temporalDenoisingSupport ? true # use temporal denoising instead of spatial denoising
, coefficientRangeCheckingSupport ? false # decoder checks if intermediate transform coefficients are in valid range
, vp9HighbitdepthSupport ? true # 10/12 bit color support in VP9
, experimentalSupport ? false # experimental features
# Experimental features
, experimentalSpatialSvcSupport ? false # Spatial scalable video coding
, experimentalFpMbStatsSupport ? false
, experimentalEmulateHardwareSupport ? false
}:

let
  inherit (stdenv) isi686 isx86_64 isArm is64bit isMips isDarwin isCygwin;
  inherit (stdenv.lib) enableFeature optional optionals;
in

assert vp8DecoderSupport || vp8EncoderSupport || vp9DecoderSupport || vp9EncoderSupport;
assert internalStatsSupport && (vp9DecoderSupport || vp9EncoderSupport) -> postprocSupport;
/* If spatialResamplingSupport not enabled, build will fail with undeclared variable errors.
   Variables called in vpx_scale/generic/vpx_scale.c are declared by vpx_scale/vpx_scale_rtcd.pl,
   but is only executed if spatialResamplingSupport is enabled */
assert spatialResamplingSupport;
assert postprocVisualizerSupport -> postprocSupport;
assert unitTestsSupport -> curl != null && coreutils != null;
assert vp9HighbitdepthSupport -> (vp9DecoderSupport || vp9EncoderSupport);
assert isCygwin -> unitTestsSupport && webmIOSupport && libyuvSupport;

stdenv.mkDerivation rec {
  name = "libvpx-${version}";
  version = "1.6.1";

  src = fetchFromGitHub {
    owner = "webmproject";
    repo = "libvpx";
    rev = "v${version}";
    sha256 = "10fs7xilf2bsj5bqw206lb5r5dgl84p5m6nibiirk28lmjx1i3l0";
  };

  patchPhase = ''patchShebangs .'';

  outputs = [ "bin" "dev" "out" ];
  setOutputFlags = false;

  configureFlags = [
    (enableFeature (vp8EncoderSupport || vp8DecoderSupport) "vp8")
    (enableFeature vp8EncoderSupport "vp8-encoder")
    (enableFeature vp8DecoderSupport "vp8-decoder")
    (enableFeature (vp9EncoderSupport || vp9DecoderSupport) "vp9")
    (enableFeature vp9EncoderSupport "vp9-encoder")
    (enableFeature vp9DecoderSupport "vp9-decoder")
    (enableFeature extraWarningsSupport "extra-warnings")
    (enableFeature werrorSupport "werror")
    "--disable-install-docs"
    (enableFeature examplesSupport "install-bins")
    "--enable-install-libs"
    "--disable-install-srcs"
    (enableFeature debugSupport "debug")
    (enableFeature gprofSupport "gprof")
    (enableFeature gcovSupport "gcov")
    # Required to build shared libraries
    (enableFeature (!isCygwin) "pic")
    (enableFeature optimizationsSupport "optimizations")
    (enableFeature runtimeCpuDetectSupport "runtime-cpu-detect")
    (enableFeature thumbSupport "thumb")
    "--enable-libs"
    (enableFeature examplesSupport "examples")
    "--disable-docs"
    "--as=yasm"
    # Limit default decoder max to WHXGA
    (if sizeLimitSupport then "--size-limit=5120x3200" else null)
    "--disable-codec-srcs"
    (enableFeature debugLibsSupport "debug-libs")
    (enableFeature isMips "dequant-tokens")
    (enableFeature isMips "dc-recon")
    (enableFeature postprocSupport "postproc")
    (enableFeature (postprocSupport && (vp9DecoderSupport || vp9EncoderSupport)) "vp9-postproc")
    (enableFeature multithreadSupport "multithread")
    (enableFeature internalStatsSupport "internal-stats")
    (enableFeature spatialResamplingSupport "spatial-resampling")
    (enableFeature realtimeOnlySupport "realtime-only")
    (enableFeature ontheflyBitpackingSupport "onthefly-bitpacking")
    (enableFeature errorConcealmentSupport "error-concealment")
    # Shared libraries are only supported on ELF platforms
    (if isDarwin || isCygwin then
       "--enable-static --disable-shared"
     else
       "--disable-static --enable-shared")
    (enableFeature smallSupport "small")
    (enableFeature postprocVisualizerSupport "postproc-visualizer")
    (enableFeature unitTestsSupport "unit-tests")
    (enableFeature webmIOSupport "webm-io")
    (enableFeature libyuvSupport "libyuv")
    (enableFeature decodePerfTestsSupport "decode-perf-tests")
    (enableFeature encodePerfTestsSupport "encode-perf-tests")
    (enableFeature multiResEncodingSupport "multi-res-encoding")
    (enableFeature temporalDenoisingSupport "temporal-denoising")
    (enableFeature (temporalDenoisingSupport && (vp9DecoderSupport || vp9EncoderSupport)) "vp9-temporal-denoising")
    (enableFeature coefficientRangeCheckingSupport "coefficient-range-checking")
    (enableFeature (vp9HighbitdepthSupport && is64bit) "vp9-highbitdepth")
    (enableFeature (experimentalSpatialSvcSupport ||
                    experimentalFpMbStatsSupport ||
                    experimentalEmulateHardwareSupport) "experimental")
    # Experimental features
  ] ++ optional experimentalSpatialSvcSupport "--enable-spatial-svc"
    ++ optional experimentalFpMbStatsSupport "--enable-fp-mb-stats"
    ++ optional experimentalEmulateHardwareSupport "--enable-emulate-hardware";

  nativeBuildInputs = [ perl yasm ];

  buildInputs = [ ]
    ++ optionals unitTestsSupport [ coreutils curl ];

  enableParallelBuilding = true;

  postInstall = ''moveToOutput bin "$bin" '';

  crossAttrs = let
    isCygwin = stdenv.cross.libc == "msvcrt";
    isDarwin = stdenv.cross.libc == "libSystem";
  in {
    configurePlatforms = [];
    configureFlags = configureFlags ++ [
      #"--extra-cflags="
      #"--extra-cxxflags="
      #"--prefix="
      #"--libc="
      #"--libdir="
      "--enable-external-build"
      # libvpx darwin targets include darwin version (ie. ARCH-darwinXX-gcc, XX being the darwin version)
      # See all_platforms: https://github.com/webmproject/libvpx/blob/master/configure
      # Darwin versions: 10.4=8, 10.5=9, 10.6=10, 10.7=11, 10.8=12, 10.9=13, 10.10=14
      "--force-target=${stdenv.cross.config}${(
              if isDarwin then (
                if      stdenv.cross.osxMinVersion == "10.10" then "14"
                else if stdenv.cross.osxMinVersion == "10.9"  then "13"
                else if stdenv.cross.osxMinVersion == "10.8"  then "12"
                else if stdenv.cross.osxMinVersion == "10.7"  then "11"
                else if stdenv.cross.osxMinVersion == "10.6"  then "10"
                else if stdenv.cross.osxMinVersion == "10.5"  then "9"
                else "8")
              else "")}-gcc"
      (if isCygwin then "--enable-static-msvcrt" else "")
    ];
  };

  meta = with stdenv.lib; {
    description = "WebM VP8/VP9 codec SDK";
    homepage    = http://www.webmproject.org/;
    license     = licenses.bsd3;
    maintainers = with maintainers; [ codyopel ];
    platforms   = platforms.all;
  };
}
