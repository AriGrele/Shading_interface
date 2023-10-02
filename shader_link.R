shader=(\(path){
  path
  return(function(code){
    write(code,'input.txt')
    system2('open',paste0(path,'/program/shader_windows.console.exe'))})
  })(funr::get_script_path())

dec2bin=function(n){ #takes input of positive numeric decimal
  if(is.na(n)){return(rep('-',32))}
  output=as.numeric(intToBits(n))
  
  return(output)}

bin2dec=function(n){
  strtoi(stringi::stri_reverse(n),base=2)} #takes input of vector representation of binary value

tif2png=function(tif,png){
  cat('Loading TIF image\n')
  img=(raster::raster(tif)|>
         as.matrix())
  
  cat('Converting values to png layers\n')
  img[is.na(img)]=0
  n=unique(as.numeric(img))
  
  lookup=
    sapply(n,dec2bin)|>
    paste(collapse='')|>
    stringi::stri_sub(seq(1,32*length(n),by=32),length=32)|>
    sapply(\(s)stringi::stri_sub(s,c(1,9,17,25),length=8))|>
    apply(1,\(n)bin2dec(n))|>
    data.table::as.data.table()|>
    cbind(as.character(n))|>
    setNames(c(1,2,3,4,'n'))
  
  data.table::setindex(lookup,n)
  
  output=lookup[as.character(img),on='n']
  output=lapply(1:3,\(l)matrix(output[[l]],ncol=ncol(img)))|>
    c(list((img>=0)))|>
    simplify2array()
  
  output[is.na(output[,,4])]=0
  
  cat('Saving PNG image\n')
  if(all(is.na(output[,,4]))){
    cat('No data\n')
    return()}
  
  png::writePNG(output[,,],png)}

t=Sys.time()
tif2png('C:/Users/Ari/Downloads/Normal_1991_2020_bioclim/Normal_1991_2020_EXT.tif','C:/Users/Ari/Desktop/tif.png')
Sys.time()-t
