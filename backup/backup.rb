#!/usr/bin/env ruby
require 'optparse'

# Методы `checked_run`, `warning` и `if __FILE__` были найдены в старых лабораторных

def checked_run(*args, dir: nil)
  command = args.join(' ')
  if !dir.nil?
    command = "cd #{dir} && #{command}"
  end
  puts "Command #{command}"
  system(command)    
end

def warning(dir,backup,method)
  unless (method == "zip" || method == "unzip")   
    puts "Введите метод zip или unzip"
    exit(1)
  end

  unless (File.exist?(File.expand_path(dir)))
    puts "Введите правильный путь до директории проекта"
    exit(1)
  end

  unless (File.exist?(File.expand_path(backup)))
    puts "Введите правильный путь для местоположения архива"
    exit(1)
  end
end

if __FILE__ == $0
  options = {}
  OptionParser.new do |opt|
    opt.on('--dir dir') { |o| options[:dirpath] = o }
    opt.on('--backup backup') { |o| options[:backuppath] = o }
    opt.on('--method method') { |o| options[:method] = o }
  end.parse!
  if options.size != 3    
    puts "Введите три параметра: (--dir=dir,--backup=backup,--method=zip/unzip)"
    puts "dir - Путь до директории с папкой backup"
    puts "backup - Путь до директории которая содержит(будет содержать) backup-архив"
    puts "method - zip(заархивировать)/unzip(распаковать)"
  exit(1)
  end
  puts options
  warning(options[:dirpath],options[:backuppath],options[:method])
  main(options[:dirpath],options[:backuppath],options[:method])
end


# Информацию про бэкап именованных volumes (В моем случае это `kanboard_data` и `drone-server-data`) нашел здесь 
# https://medium.com/@loomchild/backup-restore-docker-named-volumes-350397b8e362

def main(dir,backup,method)
  name = nil
  absolutedir = File.expand_path(dir)
  absolutebackup = File.expand_path(backup)
  
  if method == "zip"
    puts("Введите имя создаваемого архива обязательно с расширением tar(пример backup.tar)")
    name = gets.chomp
    if(name=="exit")
    exit(1)
    end
    if !File.exist?(File.join(absolutebackup, name))
      checked_run('sudo','rm','-rf','/tmp/currentbackup/')
      checked_run('sudo','mkdir','/tmp/currentbackup/')
      checked_run('sudo','cp','-r',File.join(absolutedir,'gogs'), '/tmp/currentbackup/gogs/')
      checked_run('sudo','cp','-r',File.join(absolutedir,'drone'),'/tmp/currentbackup/drone/') 
      checked_run('sudo','cp','-r',File.join(absolutedir,'mysql'),'/tmp/currentbackup/mysql/') 
      checked_run('sudo','docker','run', '--rm', '-v', 'kanboard_data:/volume', '-v', '/tmp/currentbackup:/backup', 'alpine', 'tar', '-cjf', 'backup/kanboard_data.tar.bz2', '-C', '/volume', './' )
      checked_run('sudo','docker','run', '--rm', '-v', 'drone-server-data:/volume', '-v', '/tmp/currentbackup:/backup', 'alpine', 'tar', '-cjf', 'backup/drone-server-data.tar.bz2', '-C', '/volume', './' )
      checked_run('sudo','tar','-cvf',File.join(absolutebackup,name),'/tmp/currentbackup/')
      checked_run('sudo','rm','-rf','/tmp/currentbackup')
    else
      puts "Архив с таким именем существует, введите другое имя для создания нового архива"
      main(dir,backup,method)
    end
  elsif method == "unzip"
    puts("Введите имя архива с расширением tar, который нужно распаковать(пример backup.tar)")
    name = gets.chomp
    if(name=="exit")
      exit(1)
    end
    if File.exist?(File.join(absolutebackup, name))
      checked_run('sudo','rm','-rf', File.join(absolutedir,'gogs'))
      checked_run('sudo','rm','-rf',File.join(absolutedir,'drone'))
      checked_run('sudo','rm','-rf',File.join(absolutedir,'mysql'))
      checked_run('sudo','tar','-xvf',File.join(absolutebackup, name),'-C',File.join(absolutedir,'backup'))
      checked_run('sudo','cp','-r',File.join(absolutedir,'backup','tmp','currentbackup','gogs'),File.join(absolutedir,'gogs'))
      checked_run('sudo','cp','-r',File.join(absolutedir,'backup','tmp','currentbackup','drone'),File.join(absolutedir,'drone'))
      checked_run('sudo','cp','-r',File.join(absolutedir,'backup','tmp','currentbackup','mysql'),File.join(absolutedir,'mysql'))
      checked_run('sudo','mkdir','/tmp/currentbackup/')
      checked_run('sudo','mv',File.join(absolutedir,'backup','tmp','currentbackup','kanboard_data.tar.bz2'),'/tmp/currentbackup/')
      checked_run('sudo','mv',File.join(absolutedir,'backup','tmp','currentbackup','drone-server-data.tar.bz2'),'/tmp/currentbackup/')
      checked_run('sudo','docker','run','--rm','-v','kanboard_data:/volume','-v','/tmp/currentbackup:/backup','alpine','sh','-c','"','rm','-rf','/volume/*','/volume/..?*','/volume/.[!.]*',';','tar', '-C', '/volume/', '-xjf', 'backup/kanboard_data.tar.bz2','"')
      checked_run('sudo','docker','run','--rm','-v','drone-server-data:/volume','-v','/tmp/currentbackup:/backup','alpine','sh','-c','"','rm','-rf','/volume/*','/volume/..?*','/volume/.[!.]*',';','tar', '-C', '/volume/', '-xjf', 'backup/drone-server-data.tar.bz2','"')
      checked_run('sudo','rm','-rf',File.join(absolutedir,'backup','tmp'))
      checked_run('sudo','rm','-rf','/tmp/currentbackup/')
    else
      puts("Архива с введенным именем не существует, введите правильное имя")
      main(dir,backup,method)
    end
  end
end
