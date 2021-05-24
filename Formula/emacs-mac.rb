class EmacsMac < Formula
  desc "GNU Emacs for Mac + extras (Based on YAMAMOTO Mitsuharu's Mac port)"
  homepage "https://github.com/choppsv1/emacs-mac"
  url "https://github.com/choppsv1/emacs-mac/archive/refs/tags/27.2-mac-1.5.tar.gz"
  version "27.2-mac-1.5"
  sha256 "275430584365c4f485b1f6ef2a66d8a9738cab1b3d867a224d1d908ed0140fc6"
  head "https://github.com/choppsv1/emacs-mac.git"

  option "without-modules", "Build without dynamic modules support"
  option "with-ctags", "Don't remove the ctags executable that emacs provides"
  option "without-starter", "Build without a starter script to start emacs GUI from CLI"

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  depends_on "pkg-config" => :build
  depends_on "gnutls"
  depends_on "jansson"
  depends_on "texinfo"
  depends_on "librsvg" => :recommended
  depends_on "libxml2" => :recommended
  depends_on "imagemagick" => :optional
  depends_on "mailutils" => :optional

  uses_from_macos "libxml2"
  uses_from_macos "ncurses"

  # patch for multi-tty support, see the following links for details
  # https://bitbucket.org/mituharu/emacs-mac/pull-requests/2/add-multi-tty-support-to-be-on-par-with/diff
  # https://ylluminarious.github.io/2019/05/23/how-to-fix-the-emacs-mac-port-for-multi-tty-access/
  patch do
    url "https://raw.githubusercontent.com/railwaycat/homebrew-emacsmacport/667f0efc08506facfc6963ac1fd1d5b9b777e094/patches/multi-tty-27.diff"
    sha256 "5a13e83e79ce9c4a970ff0273e9a3a07403cc07f7333a0022b91c191200155a1"
  end

  def install
    args = [
      "--disable-silent-rules",
      "--enable-locallisppath=#{HOMEBREW_PREFIX}/share/emacs/site-lisp",
      "--enable-mac-app=#{prefix}",
      "--infodir=#{info}/emacs",
      "--prefix=#{prefix}",
      "--with-gnutls",
      "--with-mac",
      "--with-xml2",
    ]
    args << "--with-imagemagick" if build.with? "imagemagick"
    args << "--with-modules" if build.with? "modules"
    args << "--without-pop" if build.with? "mailutils"
    args << "--with-rsvg" if build.with? "librsvg"

    system "./autogen.sh"
    system "./configure", *args
    system "make"
    system "make", "install"
    prefix.install "NEWS-mac"

    # Follow Homebrew and don't install ctags from Emacs. This allows Vim
    # and Emacs and exuberant ctags to play together without violence.
    if build.without? "ctags"
      (bin/"ctags").unlink
      (share/man/man1/"ctags.1.gz").unlink
    end

    if build.with? "starter"
      # Replace the symlink with one that starts GUI
      # alignment the behavior with cask
      # borrow the idea from emacs-plus
      (bin/"emacs").unlink
      (bin/"emacs").write <<~EOS
        #!/bin/bash
        exec #{prefix}/Emacs.app/Contents/MacOS/Emacs.sh "$@"
      EOS
    end
  end

  def caveats
    <<~EOS
      This is GNU Emacs based on YAMAMOTO Mitsuharu's "Mac port" additions and
      also included ones from Christian Hopps. This provides a native GUI
      support for Mac OS X 10.6 - 11.0. After installing, see README-mac and
      NEWS-mac in #{prefix} for the port details.

      Emacs.app was installed to:
        #{prefix}

      To link the application to default Homebrew App location:
        ln -s #{prefix}/Emacs.app /Applications
      Other ways please refer:
        https://github.com/railwaycat/homebrew-emacsmacport/wiki/Alternative-way-of-place-Emacs.app-to-Applications-directory

      If you are using Doom Emacs, be sure to run doom sync:
        ~/.emacs.d/doom sync

      For an Emacs.app CLI starter, see:
        https://gist.github.com/4043945
    EOS
  end

  test do
    assert_equal "4", shell_output("#{bin}/emacs --batch --eval=\"(print (+ 2 2))\"").strip
  end
end
