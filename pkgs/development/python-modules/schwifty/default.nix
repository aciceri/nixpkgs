{
  lib,
  buildPythonPackage,
  fetchPypi,

  # build-system
  hatchling,
  hatch-vcs,

  # dependencies
  importlib-resources,
  iso3166,
  pycountry,
  rstr,

  # optional-dependencies
  pydantic,

  # tests
  pytestCheckHook,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "schwifty";
  version = "2025.1.0";
  pyproject = true;

  disabled = pythonOlder "3.9";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-9JLzy+o76x/gvxGokHXm5BOl9QDuGv2ymhJKmomxoso=";
  };

  build-system = [
    hatchling
    hatch-vcs
  ];

  dependencies = [
    iso3166
    pycountry
    rstr
  ] ++ lib.optionals (pythonOlder "3.12") [ importlib-resources ];

  optional-dependencies = {
    pydantic = [ pydantic ];
  };

  nativeCheckInputs = [
    pytestCheckHook
  ] ++ lib.flatten (lib.attrValues optional-dependencies);

  pythonImportsCheck = [ "schwifty" ];

  meta = with lib; {
    changelog = "https://github.com/mdomke/schwifty/blob/${version}/CHANGELOG.rst";
    description = "Validate/generate IBANs and BICs";
    homepage = "https://github.com/mdomke/schwifty";
    license = licenses.mit;
    maintainers = with maintainers; [ milibopp ];
  };
}
