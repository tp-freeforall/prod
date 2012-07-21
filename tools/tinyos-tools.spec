Summary: TinyOS tools
Name: tinyos-tools
Version: %{version}
Release: %{release}
License: Please see sources
Packager: Eric B. Decker <cire831@gmail.com>
Group: Development/Tools
Requires: nesc

%description
Various tools (mig/ncc/ncg, motelist, tos-*, etc) used by TinyOS
(mig/ncc/ncg, motelist, tos-*, etc). The sources for these tools is
found in the TinyOS source repository under tinyos-2.x/tools.

%install
rsync -a %{prefix} %{buildroot}

%files
/usr
