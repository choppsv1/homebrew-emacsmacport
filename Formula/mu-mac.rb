# NOTE: Odd release numbers indicate unstable releases.
# Please only submit PRs for [x.x.even] version numbers:
# https://github.com/djcb/mu/commit/23f4a64bdcdee3f9956a39b9a5a4fd0c5c2370ba
class MuMac < Formula
  desc "Tool (using emacs-mac) for searching e-mail messages stored in the maildir-format"
  homepage "https://www.djcbsoftware.nl/code/mu/"
  url "https://github.com/djcb/mu/releases/download/v1.12.7/mu-1.12.7.tar.xz"
  sha256 "d916ba9b8ada90996b37eedf7f5fc70c35eb77f47fd933a502fbe0dccf2a6529"
  license "GPL-3.0-or-later"

  # We restrict matching to versions with an even-numbered minor version number,
  # as an odd-numbered minor version number indicates a development version:
  # https://github.com/djcb/mu/commit/23f4a64bdcdee3f9956a39b9a5a4fd0c5c2370ba
  livecheck do
    url :stable
    regex(/^v?(\d+\.\d*[02468](?:\.\d+)*)$/i)
  end

  head do
    # 1.7.9 :revision => "a51272a2e6"
    # url "https://github.com/djcb/mu.git", :revision => "6becc657c11884c1d4a536e3e829728a9467da54"
    url "https://github.com/djcb/mu.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "autoconf-archive" => :build
    depends_on "automake" => :build
  end

  depends_on "emacs-mac" => :build
  depends_on "libgpg-error" => :build
  depends_on "libtool" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "texinfo" => :build
  depends_on "gettext"
  depends_on "glib"
  depends_on "gmime"
  depends_on "xapian"

  conflicts_with "mu-repo", because: "both install `mu` binaries"

  fails_with gcc: "5"

  on_linux do
    depends_on "gcc"
  end

# My old
#  def install
#    system "autoreconf", "-ivf" if build.head?
#    ENV["EMACS"] = "/opt/homebrew/bin/emacs"
#    system "./configure", "--disable-dependency-tracking",
#                          "--disable-guile",
#                          "--prefix=#{prefix}",
#                          "--with-lispdir=#{elisp}"
#    system "make", "V=1"
#    system "make", "V=1", "install"
#  end

  # # from 1.8 formula
  # def install
  #   mkdir "build" do
  #     system "meson", *std_meson_args, "-Dlispdir=#{elisp}", ".."
  #     system "ninja", "-v"
  #     system "ninja", "install", "-v"
  #   end
  # end

  def install
    system "meson", "setup", "build", "-Dlispdir=#{elisp}", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  def caveats; <<~EOS
    Existing mu users are recommended to run the following after upgrading:

      mu index --rebuild
  EOS
  end

  # Regression test for:
  # https://github.com/djcb/mu/issues/397
  # https://github.com/djcb/mu/issues/380
  # https://github.com/djcb/mu/issues/332
  test do
    mkdir (testpath/"cur")

    (testpath/"cur/1234567890.11111_1.host1!2,S").write <<~EOS
      From: "Road Runner" <fasterthanyou@example.com>
      To: "Wile E. Coyote" <wile@example.com>
      Date: Mon, 4 Aug 2008 11:40:49 +0200
      Message-id: <1111111111@example.com>

      Beep beep!
    EOS

    (testpath/"cur/0987654321.22222_2.host2!2,S").write <<~EOS
      From: "Wile E. Coyote" <wile@example.com>
      To: "Road Runner" <fasterthanyou@example.com>
      Date: Mon, 4 Aug 2008 12:40:49 +0200
      Message-id: <2222222222@example.com>
      References: <1111111111@example.com>

      This used to happen outdoors. It was more fun then.
    EOS

    system bin/"mu", "init", "--muhome=#{testpath}", "--maildir=#{testpath}"
    system bin/"mu", "index", "--muhome=#{testpath}"

    mu_find = "#{bin}/mu find --muhome=#{testpath} "
    find_message = "#{mu_find} msgid:2222222222@example.com"
    find_message_and_related = "#{mu_find} --include-related msgid:2222222222@example.com"

    assert_equal 1, shell_output(find_message).lines.count
    assert_equal 2, shell_output(find_message_and_related).lines.count, <<~EOS
      You tripped over https://github.com/djcb/mu/issues/380
        --related doesn't work. Everything else should
    EOS
  end
end
