class Zxtune123 < Formula
  desc "Command-line chiptune player and converter"
  homepage "https://zxtune.ru"
  url "https://github.com/vitamin-caig/zxtune/archive/refs/tags/r5112.tar.gz"
  version "r5112"
  sha256 "82c61605a344dc0396a4187e741a7d504388a1d86876e30331187e8f6221ccd8"
  license "LGPL-3.0-only"

  bottle do
    root_url "https://github.com/anteo/homebrew-zxtune/releases/download/zxtune123-r5112"
    sha256 cellar: :any, arm64_golden_gate: "c93122bd92cd30d803b29adc028f5e81b406a31d6103a9bcd65c48d94606a753"
  end

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
             "root.version=r5112",
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
index f4dc901f3..b78b2c71b 100644
--- a/src/core/plugins/archives/raw_supp.cpp
+++ b/src/core/plugins/archives/raw_supp.cpp
@@ -635,7 +635,7 @@ namespace ZXTune::Raw
 
     void Move(std::size_t step)
     {
-      if (!Subdata.unique())
+      if (Subdata.use_count() != 1)
       {
         Dbg("Subdata is captured. Duplicate.");
         Subdata = MakePtr<ScanDataContainer>(Parent->GetData(), Subdata->GetOffset() + step);
@@ -929,7 +929,7 @@ namespace ZXTune::Raw
         const std::size_t offset = subLocation->GetOffset();
         progress.Report(offset);
         const auto detectResult = usedPlugins.Detect(subLocation, callback);
-        if (!subLocation.unique())
+        if (subLocation.use_count() != 1)
         {
           Dbg("Sublocation is captured. Duplicate.");
           subLocation = MakePtr<ScanDataLocation>(input, offset);
diff --git a/src/io/providers/gates/curl_api_dynamic.cpp b/src/io/providers/gates/curl_api_dynamic.cpp
index 6c78e0ba5..300c78fa5 100644
--- a/src/io/providers/gates/curl_api_dynamic.cpp
+++ b/src/io/providers/gates/curl_api_dynamic.cpp
@@ -30,7 +30,7 @@ namespace IO::Curl
 
     std::vector<StringView> PosixAlternatives() const override
     {
-      return {"libcurl.so.3"sv, "libcurl.so.4"sv};
+      return {"libcurl.so.3"sv, "libcurl.so.4"sv, "libcurl.dylib"sv, "@rpath/libcurl.dylib"sv};
     }
 
     std::vector<StringView> WindowsAlternatives() const override
diff --git a/src/sound/backends/gates/flac_api_dynamic.cpp b/src/sound/backends/gates/flac_api_dynamic.cpp
index a54008298..17c32ea1c 100644
--- a/src/sound/backends/gates/flac_api_dynamic.cpp
+++ b/src/sound/backends/gates/flac_api_dynamic.cpp
@@ -30,7 +30,7 @@ namespace Sound::Flac
 
     std::vector<StringView> PosixAlternatives() const override
     {
-      return {"libFLAC.so.7"sv, "libFLAC.so.8"sv};
+      return {"libFLAC.so.7"sv, "libFLAC.so.8"sv, "libFLAC.dylib"sv, "@rpath/libFLAC.dylib"sv};
     }
 
     std::vector<StringView> WindowsAlternatives() const override
diff --git a/src/sound/backends/gates/mp3_api_dynamic.cpp b/src/sound/backends/gates/mp3_api_dynamic.cpp
index e7d2acd52..49167469e 100644
--- a/src/sound/backends/gates/mp3_api_dynamic.cpp
+++ b/src/sound/backends/gates/mp3_api_dynamic.cpp
@@ -30,7 +30,7 @@ namespace Sound::Mp3
 
     std::vector<StringView> PosixAlternatives() const override
     {
-      return {"libmp3lame.so.0"sv};
+      return {"libmp3lame.so.0"sv, "libmp3lame.dylib"sv, "@rpath/libmp3lame.dylib"sv};
     }
 
     std::vector<StringView> WindowsAlternatives() const override
diff --git a/src/sound/backends/gates/ogg_api_dynamic.cpp b/src/sound/backends/gates/ogg_api_dynamic.cpp
index e30571579..cbb3d93e6 100644
--- a/src/sound/backends/gates/ogg_api_dynamic.cpp
+++ b/src/sound/backends/gates/ogg_api_dynamic.cpp
@@ -30,7 +30,7 @@ namespace Sound::Ogg
 
     std::vector<StringView> PosixAlternatives() const override
     {
-      return {"libogg.so.0"sv};
+      return {"libogg.so.0"sv, "libogg.dylib"sv, "@rpath/libogg.dylib"sv};
     }
 
     std::vector<StringView> WindowsAlternatives() const override
diff --git a/src/sound/backends/gates/openal_api_dynamic.cpp b/src/sound/backends/gates/openal_api_dynamic.cpp
index 5542ba22d..dd218b7e4 100644
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
diff --git a/src/sound/backends/gates/vorbis_api_dynamic.cpp b/src/sound/backends/gates/vorbis_api_dynamic.cpp
index ee8e799ab..659464135 100644
--- a/src/sound/backends/gates/vorbis_api_dynamic.cpp
+++ b/src/sound/backends/gates/vorbis_api_dynamic.cpp
@@ -30,7 +30,7 @@ namespace Sound::Vorbis
 
     std::vector<StringView> PosixAlternatives() const override
     {
-      return {"libvorbis.so.0"sv};
+      return {"libvorbis.so.0"sv, "libvorbis.dylib"sv, "@rpath/libvorbis.dylib"sv};
     }
 
     std::vector<StringView> WindowsAlternatives() const override
diff --git a/src/sound/backends/gates/vorbisenc_api_dynamic.cpp b/src/sound/backends/gates/vorbisenc_api_dynamic.cpp
index ffdd219b9..4c2941bbf 100644
--- a/src/sound/backends/gates/vorbisenc_api_dynamic.cpp
+++ b/src/sound/backends/gates/vorbisenc_api_dynamic.cpp
@@ -30,7 +30,7 @@ namespace Sound::VorbisEnc
 
     std::vector<StringView> PosixAlternatives() const override
     {
-      return {"libvorbisenc.so.2"sv};
+      return {"libvorbisenc.so.2"sv, "libvorbisenc.dylib"sv, "@rpath/libvorbisenc.dylib"sv};
     }
 
     std::vector<StringView> WindowsAlternatives() const override
