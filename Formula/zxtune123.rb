class Zxtune123 < Formula
  desc "Command-line chiptune player and converter"
  homepage "https://zxtune.ru"
  url "https://github.com/vitamin-caig/zxtune/archive/ee9db2825c605c74163df1fa407af705c9e02342.tar.gz"
  version "2026.10.14"
  sha256 "536cb2d551fa6f03ec8e4aa7f679ff7bf9974722c8338d8f5a1e7d74ab601e45"
  license "LGPL-3.0-only"

  depends_on "boost"
  depends_on "curl"
  depends_on "flac"
  depends_on "lame"
  depends_on "libogg"
  depends_on "libvorbis"
  depends_on "openal-soft"

  # The pinned upstream revision predates these macOS/libc++ compatibility fixes.
  # Keep this patch until an upstream revision contains the same changes.
  patch :DATA

  def install
    dependencies = %w[boost curl flac lame libogg libvorbis openal-soft]
    include_dirs = dependencies.map { |name| Formula[name].opt_include }
    library_dirs = dependencies.map { |name| Formula[name].opt_lib }
    rpaths = library_dirs.map { |path| "-Wl,-rpath,#{path}" }
    rpaths.unshift("-Wl,-headerpad_max_install_names")

    cd "apps/zxtune123" do
      system "make", "-j#{ENV.make_jobs}",
             "platform=darwin",
             "system.zlib=1",
             "includes.dirs.darwin=#{include_dirs.join(' ')}",
             "libraries.dirs.darwin=#{library_dirs.join(' ')}",
             "cxx_flags=-DFMT_CONSTEVAL=",
             "ld_flags=#{rpaths.join(' ')}"
    end

    bin.install "bin/darwin/release/zxtune123"
    doc.install "README.md", "LICENSE.md"
  end

  test do
    output = shell_output("#{bin}/zxtune123 --list-backends")
    %w[openal mp3 ogg flac].each do |backend|
      assert_match(/Backend:\s+#{backend}\n.*?Status:\s+Available/m, output)
    end
  end
end

__END__
diff --git a/src/core/plugins/archives/raw_supp.cpp b/src/core/plugins/archives/raw_supp.cpp
index 0b5d6b49d..188335366 100644
--- a/src/core/plugins/archives/raw_supp.cpp
+++ b/src/core/plugins/archives/raw_supp.cpp
@@ -427,7 +427,7 @@ namespace ZXTune::Raw
 
     void Move(std::size_t step)
     {
-      if (!Subdata.unique())
+      if (Subdata.use_count() != 1)
       {
         Dbg("Subdata is captured. Duplicate.");
         Subdata = MakePtr<ScanDataContainer>(Parent->GetData(), Subdata->GetOffset() + step);
@@ -853,7 +853,7 @@ namespace ZXTune::Raw
         const std::size_t offset = subLocation->GetOffset();
         progress.Report(offset);
         const auto detectResult = usedPlugins.Detect(subLocation, callback);
-        if (!subLocation.unique())
+        if (subLocation.use_count() != 1)
         {
           Dbg("Sublocation is captured. Duplicate.");
           subLocation = MakePtr<ScanDataLocation>(input, offset);
--- a/src/sound/backends/gates/flac_api_dynamic.cpp
+++ b/src/sound/backends/gates/flac_api_dynamic.cpp
@@ -30,7 +30,7 @@ namespace Sound::Flac
 
     std::vector<StringView> PosixAlternatives() const override
     {
-      return {"libFLAC.so.7"sv, "libFLAC.so.8"sv};
+      return {"libFLAC.so.7"sv, "libFLAC.so.8"sv, "libFLAC.dylib"sv, "@rpath/libFLAC.dylib"sv};
     }
 
     std::vector<StringView> WindowsAlternatives() const override
--- a/src/sound/backends/gates/mp3_api_dynamic.cpp
+++ b/src/sound/backends/gates/mp3_api_dynamic.cpp
@@ -30,7 +30,7 @@ namespace Sound::Mp3
 
     std::vector<StringView> PosixAlternatives() const override
     {
-      return {"libmp3lame.so.0"sv};
+      return {"libmp3lame.so.0"sv, "libmp3lame.dylib"sv, "@rpath/libmp3lame.dylib"sv};
     }
 
     std::vector<StringView> WindowsAlternatives() const override
--- a/src/sound/backends/gates/ogg_api_dynamic.cpp
+++ b/src/sound/backends/gates/ogg_api_dynamic.cpp
@@ -30,7 +30,7 @@ namespace Sound::Ogg
 
     std::vector<StringView> PosixAlternatives() const override
     {
-      return {"libogg.so.0"sv};
+      return {"libogg.so.0"sv, "libogg.dylib"sv, "@rpath/libogg.dylib"sv};
     }
 
     std::vector<StringView> WindowsAlternatives() const override
--- a/src/sound/backends/gates/openal_api_dynamic.cpp
+++ b/src/sound/backends/gates/openal_api_dynamic.cpp
@@ -30,7 +30,8 @@ namespace Sound::OpenAl
 
     std::vector<StringView> PosixAlternatives() const override
     {
-      return {"libopenal.so.1"sv, "OpenAL.framework/OpenAL"sv};
+      return {"libopenal.so.1"sv, "OpenAL.framework/OpenAL"sv, "libopenal.dylib"sv,
+              "@rpath/libopenal.dylib"sv};
     }
 
     std::vector<StringView> WindowsAlternatives() const override
--- a/src/sound/backends/gates/vorbis_api_dynamic.cpp
+++ b/src/sound/backends/gates/vorbis_api_dynamic.cpp
@@ -30,7 +30,7 @@ namespace Sound::Vorbis
 
     std::vector<StringView> PosixAlternatives() const override
     {
-      return {"libvorbis.so.0"sv};
+      return {"libvorbis.so.0"sv, "libvorbis.dylib"sv, "@rpath/libvorbis.dylib"sv};
     }
 
     std::vector<StringView> WindowsAlternatives() const override
--- a/src/sound/backends/gates/vorbisenc_api_dynamic.cpp
+++ b/src/sound/backends/gates/vorbisenc_api_dynamic.cpp
@@ -30,7 +30,7 @@ namespace Sound::VorbisEnc
 
     std::vector<StringView> PosixAlternatives() const override
     {
-      return {"libvorbisenc.so.2"sv};
+      return {"libvorbisenc.so.2"sv, "libvorbisenc.dylib"sv, "@rpath/libvorbisenc.dylib"sv};
     }
 
     std::vector<StringView> WindowsAlternatives() const override
--- a/src/io/providers/gates/curl_api_dynamic.cpp
+++ b/src/io/providers/gates/curl_api_dynamic.cpp
@@ -30,7 +30,7 @@ namespace IO::Curl
 
     std::vector<StringView> PosixAlternatives() const override
     {
-      return {"libcurl.so.3"sv, "libcurl.so.4"sv};
+      return {"libcurl.so.3"sv, "libcurl.so.4"sv, "libcurl.dylib"sv, "@rpath/libcurl.dylib"sv};
     }
 
     std::vector<StringView> WindowsAlternatives() const override
