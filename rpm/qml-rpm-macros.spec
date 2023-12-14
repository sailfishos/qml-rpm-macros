Name: qml-rpm-macros
Version: 0.1.1
Release: 1
Summary: Macros for handling QML
License: GPLv2
Source0: %{name}-%{version}.tar.gz
BuildArch:  noarch

%description
%{summary}.

%files
%defattr(-,root,root,-)
%{_rpmconfigdir}/fileattrs/qml.attr
%{_rpmconfigdir}/qmldeps.sh

%prep
%setup -q

%build

%install
install -m644 -D qml.attr %{buildroot}/%{_rpmconfigdir}/fileattrs/qml.attr
install -m755 -D qmldeps.sh %{buildroot}/%{_rpmconfigdir}/qmldeps.sh
