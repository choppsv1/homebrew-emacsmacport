class Mbsync < Formula
  desc "Synchronize a maildir with an IMAP server"
  homepage "https://isync.sourceforge.io/"
  url "https://downloads.sourceforge.net/project/isync/isync/1.4.4/isync-1.4.4.tar.gz"
  sha256 "7c3273894f22e98330a330051e9d942fd9ffbc02b91952c2f1896a5c37e700ff"
  license "GPL-2.0-or-later"
  head "https://git.code.sf.net/p/isync/isync.git", branch: "master"

  patch do
    url "file:///opt/homebrew/Library/Taps/choppsv1/homebrew-emacsmacport/add-apple-xoauth2.patch"
    sha256 "270c6dab4f397847001ae9a55689e71b4d7c0aa7c0a1bb73942467afe191fd61"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "berkeley-db"
  depends_on "openssl@1.1"

  uses_from_macos "zlib"

  def install
    # Regenerated for HEAD, and because of our patch
    if build.head?
      system "./autogen.sh"
    else
      system "autoreconf", "-fiv"
    end

    args = %W[
      --disable-dependency-tracking
      --prefix=#{prefix}
      --disable-silent-rules
    ]

    system "./configure", *args
    system "make", "install"
  end

  service do
    run [opt_bin/"mbsync", "-a"]
    run_type :interval
    interval 300
    keep_alive false
    environment_variables PATH: std_service_path_env
    log_path "/dev/null"
    error_log_path "/dev/null"
  end

  test do
    system bin/"mbsync-get-cert", "duckduckgo.com:443"
  end
end
