shader=(\(path){
  path
  return(function(code){
    write(code,'input.txt')
    system2('open',paste0(path,'/program/shader_windows.console.exe'))})
  })(funr::get_script_path())