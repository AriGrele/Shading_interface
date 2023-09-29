shader=(\(path){
  path
  return(function(code){
    write(code,'input.txt')
    system2('open',paste0(path,'/shader_interface.console.exe'))})
  })(funr::get_script_path())