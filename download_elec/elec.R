# setwd("~/Documents/Projects/streets_vox")
options(stringsAsFactors = FALSE)
# List of packages
pkg = c("tidyr", "dplyr")
# Checks if they are installed, install if not
if (length(setdiff(pkg, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(pkg, rownames(installed.packages())))}
# muniSpain and elecciones (Github)
if(!all(c("muniSpain", "infoelectoral") %in% rownames(installed.packages()))){
  if(!"devtools" %in% rownames(installed.packages())){install.packages("devtools")}
  library(devtools)
  install_github("franvillamil/muniSpain")
  install_github("rOpenSpain/infoelectoral")
}
# Load
lapply(c(pkg, "muniSpain", "infoelectoral"), library, character.only = TRUE)

# Alternative names
PP_alt = c("PP", "PP-FORO", "PP-PAR", "UPN-PP", "PP-EU", "P.P.", "P.P-E.U.", "PP-UPM")
PSOE_alt = c("PSC", "PSdeG-PSOE", "PSE-EE (PSO", "PSC-PSOE", "PSE-EE (PSOE)",
  "PSOE-NCa", "PSE-EE", "PSOE", "P.S.O.E.", "PSC (PSC-PSOE)", "PSOE-A",
  "PSE-EE(PSOE)", "PSOE de A", "PSE-EE-PSOE", "PSOE-PROGR.")


# Function to transform
elec_clean = function(rawdf, label){

  df = rawdf %>%
    mutate(siglas = ifelse(siglas %in% PP_alt, "PP", siglas)) %>%
    mutate(siglas = ifelse(siglas %in% PSOE_alt, "PSOE", siglas)) %>%
    filter(siglas %in% c("PP", "VOX", "PSOE")) %>%
    mutate(muni_code=paste0(codigo_provincia,codigo_municipio)) %>% 
    rename(censo = censo_ine) %>%
    mutate(
      validos = votos_candidaturas + votos_blancos,
      votantes = votos_candidaturas + votos_blancos + votos_nulos) %>%
    select(muni_code, votantes, validos, censo, siglas, votos) %>%
    pivot_wider(names_from = "siglas", values_from = "votos") %>%
    mutate(
      PP = PP / validos,
      PSOE = PSOE / validos,
      part = votantes / censo)

  if("VOX" %in% names(df)){ df = df %>% mutate(VOX = VOX / validos) }

  df = df %>%
    select(-c("votantes", "censo", "validos")) %>%
    rename_at(vars(-muni_code), paste0, label) %>%
    as.data.frame()

}

# -------------------------

# Download
e19_11r = municipios(tipo_eleccion = "congreso", anno = 2019, mes = "11")
e19_04r = municipios(tipo_eleccion = "congreso", anno = 2019, mes = "04")
e16_06r = municipios(tipo_eleccion = "congreso", anno = 2016, mes = "06")
e15_12r = municipios(tipo_eleccion = "congreso", anno = 2015, mes = "12")
e11_11r = municipios(tipo_eleccion = "congreso", anno = 2011, mes = "11")
e08_03r = municipios(tipo_eleccion = "congreso", anno = 2008, mes = "03")
e04_03r = municipios(tipo_eleccion = "congreso", anno = 2004, mes = "03")
e00_03r = municipios(tipo_eleccion = "congreso", anno = 2000, mes = "03")

# Clean
e19_11 = elec_clean(e19_11r, "2019_11")
e19_04 = elec_clean(e19_04r, "2019_04")
e16_06 = elec_clean(e16_06r, "2016_06")
e15_12 = elec_clean(e15_12r, "2015_12")
e11_11 = elec_clean(e11_11r, "2011_11")
e08_03 = elec_clean(e08_03r, "2008_03")
e04_03 = elec_clean(e04_03r, "2004_03")
e00_03 = elec_clean(e00_03r, "2000_03")

# Merge
elec = merge(e19_11, e19_04, all = TRUE)
elec = merge(elec, e16_06, all = TRUE)
elec = merge(elec, e15_12, all = TRUE)
elec = merge(elec, e11_11, all = TRUE)
elec = merge(elec, e08_03, all = TRUE)
elec = merge(elec, e04_03, all = TRUE)
elec = merge(elec, e00_03, all = TRUE)

# Save
write.csv(elec, "download_elec/output/elec.csv", row.names = FALSE)
