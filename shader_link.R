shader=(\(path){
  path
  return(function(code){
    write(code,'input.txt')
    system2('open',paste0(path,'/program/shader_windows.console.exe'))})
  })(funr::get_script_path())

decimalplaces=function(n){
  if(n-round(n)<=.Machine$double.eps^0.5){return(0)}
  nchar(strsplit(sub('0+$','',as.character(n)),".",fixed=T)[[1]][[2]])}

dec2bin=function(n){ #takes input of positive numeric decimal
  if(is.na(n)){return(rep('-',32))}
  output=as.numeric(intToBits(n))
  
  return(output)}

bin2dec=function(n){
  strtoi(stringi::stri_reverse(n),base=2)} #takes input of vector representation of binary value

clamp=function(x,l,u){ifelse(x<l,l,ifelse(x>u,u,x))}

split_mat=function(mat,n=16000){
  size=ceiling(dim(mat)[-3]/n) #16000 pixel max size of chunk

  lapply(1:size[2],\(x){
    lapply(1:size[1],\(y){
      cat(x,y,'  \r')
      mat[((y-1)*n+1):clamp(y*n,0,dim(mat)[1]),((x-1)*n+1):clamp(x*n,0,dim(mat)[2])]})})|>
    unlist(recursive=F)}

tif2png=function(tif,dst){
  options(scipen=999)
  cat('Loading TIF image\n')
  
  file=strsplit(tif,'/')[[1]][length(strsplit(tif,'/')[[1]])]|>
    gsub('.tif','',x=_)
  
  img=(raster::raster(tif)|>
         raster::as.matrix())
  
  images=split_mat(img)
  rm(img)
  gc()
  cat('Converting values to png layers\n')
  for(index in 1:length(images)){
    t=Sys.time()
    cat('chunk',index,'\n')
    
    img=images[[index]]
    img[is.na(img)]=0
    
    cat('*\tGrabbing unique values\n')
    n=unique(abs(as.numeric(img)))
    dp=min(c(floor(log10(256^3/max(n))),128))
    
    img=floor(img*(10^dp))
    n=unique(abs(as.numeric(img)))|>
      c(0)
    
    cat('*\tBuilding lookup table with scale of',dp,'\n')
    lookup=
      sapply(n,dec2bin)|>
      paste(collapse='')|>
      stringi::stri_sub(seq(1,32*length(n),by=32),length=32)|>
      sapply(\(s)stringi::stri_sub(s,c(1,9,17,25),length=8))|>
      apply(1,\(n)bin2dec(n))|>
      data.table::as.data.table()|>
      cbind(as.character(n))|>
      setNames(c(1,2,3,4,'n'))|>
      unique()
    
    data.table::setindex(lookup,n)
    
    cat('*\tConverting data\n')
    output=lookup[as.character(abs(img)),on='n']
    output=lapply(1:3,\(l)matrix(output[[l]]/255,ncol=ncol(img)))|>
      c(list(((img>=0)-.5)*dp/255+.5))|>
      simplify2array()
    
    output[is.na(output)]=0
    
    cat('*\tSaving PNG image\n')
    if(all(is.na(output[,,4]))){
      cat('No data\n')
      return()}
    
    dir.create(paste0(dst,'/',file),showWarnings=F)
    png::writePNG(output[,,],paste0(dst,'/',file,'/',file,'_',index,'.png'))
    rm(img)
    gc()
    cat('*\tTime:',Sys.time()-t,'\n')}}

coordinate_data=(\(path){
  path
  return(function(file,coords){
    if(!file.exists(file)){
      cat('File does not exist\n')
      return()}
    
    src=paste0(path,'/compute_output.txt')
    if(file.exists(src)){file.remove(src)}
    
    
    coords=paste0('[',sapply(coords,\(pair)paste0('[',pair[1],',',pair[2],']'))|>
                    paste(collapse=','),']')
    
    script=glue::glue('
    mode:save
    binding:2
    x:16000
    y:16000
    input: {{"set":0,"binding":[0,1,2],"type":"sampler2D","value":"{file}"}}
    coords:{{"set":0,"binding":3,"type":"vec2","value":{coords}}}
    
    #[compute]
    #version 450
    
    layout(local_size_x = 2, local_size_y = 1, local_size_z = 1) in; //in x, y dimension
     
    
    layout(set = 0, binding = 0) uniform sampler2D heightmap; //Input texture
    
    
    layout(set = 0, binding = 2, std430) restrict buffer SizeDataBuffer{{ // Texture size info
      int width;
      int height;}}
    size_data;
    
    layout(set = 0, binding = 3, std430) restrict buffer MyDataBufferx{{ //Input coordinates
        vec2 data[];}}
    coords;
         
    void main(){{
        float x    = (coords.data[gl_GlobalInvocationID.x].x+180.0)/360.0*float(size_data.width);
        float y    = (90.0-coords.data[gl_GlobalInvocationID.x].y)/180.0*float(size_data.height);
        vec2 pos   = vec2(x,y);
    
        vec4 color = texture(heightmap,pos);
        coords.data[gl_GlobalInvocationID.x].x = float(color[0]);}}')
    
    shader(script)
    
    while(!file.exists(src)){Sys.sleep(.1)}
    output=read.table(src)
    return(output)})
  })(funr::get_script_path())