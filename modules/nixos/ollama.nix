{
  ollama,
  fetchFromGitHub,
  acceleration ? null,
  rocmPackages, # Adăugat pentru acces la biblioteci
  ...
}:
# Folosim override pentru a schimba argumentele de construcție
(ollama.override { inherit acceleration; }).overrideAttrs (oldAttrs: rec {
  pname = "ollama";
  version = "0.23.2";

  src = fetchFromGitHub {
    owner = "ollama";
    repo = "ollama";
    rev = "v${version}";
    hash = "sha256-4K1+GE96Uu5w1otSiP69vNDJ03tFvr78VluIEHMzFGQ=";
  };
  postPatch = "";
  vendorHash = "sha256-Aj62Q+XvUp9MHBAYaYC6GLIP6Ut89bJHxAG7raRI0WA=";

  # Forțăm includerea bibliotecilor ROCm în mediul de execuție al binarului
  buildInputs = oldAttrs.buildInputs ++ (if acceleration == "rocm" then [
    rocmPackages.clr
    rocmPackages.hipblas
    rocmPackages.rocblas
  ] else []);
})
