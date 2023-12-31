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
    
    script='
mode:save
binding:2

input: {"set":0,"binding":[0,1,2],"type":"sampler2D","value":"image2.png"}
coords:{"set":0,"binding":3,"type":"vec2","value":[[0,-9.63637735694647],[1,3.31408984959126],[2,-115.475426344201],[3,10.4345630295575],[4,-1.48861158639193],[5,164.585737064481],[6,-115.406532464549],[7,-17.1058023255318],[8,-111.577741289511],[9,-118.236936377361],[10,-63.8589985761791],[11,162.741449475288],[-81.8880779715255,-94.4754291884601],[61.0914834961295,71.4326266944408],[80.7810041215271,105.840714471415],[10.6138718873262,31.1062753200531],[-17.5903184479102,-145.782029628754],[37.1997470129281,-142.591115618125],[-22.6855589076877,-150.103492895141],[-26.4763651834801,69.3077730853111],[60.477442452684,134.830275094137],[-16.4829221880063,-2.89260006509721],[-5.51822310313582,-160.81279233098],[52.2248648805544,21.0954274702817],[-33.9209154294804,168.217918965966],[50.6338042253628,-11.0659455601126],[-2.50913289841264,-139.633214324713],[-69.0994695900008,109.779375046492],[11.8759057950228,172.980605112389],[-64.5520353270695,-170.145339779556],[82.658147639595,129.018782526255],[-86.8428713036701,39.0014328248799],[-58.1442728592083,-119.866530820727],[26.718184389174,160.897379480302],[60.9527647588402,-113.356943735853],[-88.2482180278748,155.402873642743],[0.400898759253323,166.788967335597],[-84.7008909936994,79.2400138545781],[45.8501847786829,-26.5080908127129],[56.7187916301191,-43.1925631128252],[56.1178650381044,-20.9184502903372],[52.6228880602866,-51.1151224002242],[19.6687354333699,-45.0782003067434],[-89.2499928781763,108.099127840251],[-46.163147399202,-41.711075976491],[33.2043027319014,76.5372928977013],[-38.8254811288789,-138.071093028411],[-13.0846589617431,6.29093499854207],[30.3816198511049,83.6145825963467],[-35.5204068124294,88.8433360029012],[-84.287258782424,122.727988176048],[-42.5863029062748,143.981405217201],[-76.8636105721816,-117.664940385148],[-25.3310519596562,-177.719904072583],[61.356203276664,34.5827708300203],[-63.2631761021912,165.005567399785],[74.0367670822889,67.5670523755252],[84.8325130250305,159.465438276529],[87.0448275608942,133.317817915231],[-78.7370243109763,168.979778308421],[4.39184803515673,-47.5225672032684],[81.6481650620699,-146.089164186269],[10.2240681694821,143.061946397647],[56.2787377741188,9.30579677224159],[67.8015452530235,90.8525667898357],[-45.7537544611841,36.8969029840082],[-29.0651052910835,-67.1186333801597],[33.5288849752396,-174.306983873248],[65.6509195547551,124.526906283572],[85.4243348166347,119.492318155244],[-20.946667380631,62.9757422022521],[-39.2263751523569,-67.8887591231614],[-22.4725580681115,57.6748232077807],[46.1326544964686,62.3709314782172],[71.2988171121106,-98.3137777447701],[-77.6198350125924,68.973669167608],[5.02513434737921,20.0874257460237],[23.7987773632631,30.2473286446184],[-48.49437775556,85.6192152388394],[-14.2573006683961,-78.3668407425284],[55.9931365353987,153.91903010197],[9.03013647068292,-105.993106272072],[-11.065609571524,-87.3759261891246],[-37.3643558565527,-12.5303275790066],[-36.9880360225216,-31.5184497926384],[80.0132205337286,-148.002318665385],[83.0652156053111,-72.6976414583623],[68.6271344684064,-113.01739317365],[77.6849853247404,38.9063290692866],[74.6076539391652,143.030474530533],[58.9671023748815,-144.980804761872],[-65.3933799639344,-160.636198036373],[-69.7036730032414,-130.770144900307],[87.3207507608458,-58.4576366376132],[-29.7231996478513,71.6099561657757],[-21.9571873219684,2.92040920816362],[7.91600124444813,153.730020616204],[89.5171755971387,-1.46483128890395],[4.66921015642583,-170.312109393999],[41.7855104198679,-50.3132947906852]]}

#[compute]
#version 450

layout(local_size_x = 20, local_size_y = 1, local_size_z = 3) in; //in x, y dimension
 

layout(set = 0, binding = 0) uniform sampler2D heightmap; //Input texture


layout(set = 0, binding = 2, std430) restrict buffer SizeDataBuffer{ // Texture size info
  int width;
  int height;}
size_data;

layout(set = 0, binding = 3, std430) restrict buffer MyDataBufferx{ //Input coordinates
    vec2 data[];}
coords;
     
void main(){
    float x    = (coords.data[gl_GlobalInvocationID.x].x+180.0)/360.0*float(size_data.width);
    float y    = (90.0-coords.data[gl_GlobalInvocationID.x].y)/180.0*float(size_data.height);
    vec2 pos   = vec2(x,y);

    vec4 color = texture(heightmap,pos);
    coords.data[gl_GlobalInvocationID.x].x=0.;
    coords.data[gl_GlobalInvocationID.x].y = color.x;}
'
    
    shader(script)
    
    while(!file.exists(src)){Sys.sleep(.1)}
    output=read.table(src)
    return(output)})
  })(funr::get_script_path())