#!/usr/bin/env ruby
require 'optparse'

def checkd_run(*args, dir: nil)
    command = args.join(' ')
    if !dir.nil?
      command = "cd #{dir} && #{command}"
    end
    puts "Running #{command}"
    system(command)
end

def check_error(pathdir,pathback,method)
  unless (method == "zip" || method == "unzip")   
    puts "Метода [#{method}] не существует, запустите программу c методoм zip или unzip"
    exit(1)
  end

  unless (File.exist?(File.expand_path(pathdir)))
    puts "Введенный путь до главной директории не существует, введите правильный путь"
    exit(1)
  end

  unless (File.exist?(File.expand_path(pathback)))
    puts "Введеный путь до каталога в котром будет лежать backup-архив не существует, введите правильный путь"
    exit(1)
  end
end


# Дополнение: нашел информацию про бэкап именованных volumes (В моем случае это `kanboard_data` и `drone-server-data`) здесь 
# https://medium.com/@loomchild/backup-restore-docker-named-volumes-350397b8e362

def zip(pathdir,pathback,method)
  name = nil
  absolutepathdir = File.expand_path(pathdir)
  absolutepathback = File.expand_path(pathback)
  if method == "zip"
    puts("Введите имя создаваемого архива обязательно с расширением tar(пример backup.tar)")
    name = gets.chomp
    if(name=="exit")
    exit(1)
    end
    if !File.exist?(File.join(absolutepathback, name))
      checkd_run('sudo','rm','-rf','/tmp/currentbackup/')
      checkd_run('sudo','mkdir','/tmp/currentbackup/')
      checkd_run('sudo','cp','-r',File.join(absolutepathdir,'gogs'), '/tmp/currentbackup/gogs/')
      checkd_run('sudo','cp','-r',File.join(absolutepathdir,'drone'),'/tmp/currentbackup/drone/') 
      checkd_run('sudo','cp','-r',File.join(absolutepathdir,'mysql'),'/tmp/currentbackup/mysql/') 
      checkd_run('sudo','docker','run', '--rm', '-v', 'kanboard_data:/volume', '-v', '/tmp/currentbackup:/backup', 'alpine', 'tar', '-cjf', 'backup/kanboard_data.tar.bz2', '-C', '/volume', './' )
      checkd_run('sudo','docker','run', '--rm', '-v', 'drone-server-data:/volume', '-v', '/tmp/currentbackup:/backup', 'alpine', 'tar', '-cjf', 'backup/drone-server-data.tar.bz2', '-C', '/volume', './' )
      checkd_run('sudo','tar','-cvf',File.join(absolutepathback,name),'/tmp/currentbackup/')
      checkd_run('sudo','rm','-rf','/tmp/currentbackup')
    else
      puts "Архив с таким именем существует, введите другое имя для создания нового архива"
      zip(pathdir,pathback,method)
    end
  elsif method == "unzip"
    puts("Введите имя архива с расширением tar, который нужно распаковать(пример backup.tar)")
    name = gets.chomp
    if(name=="exit")
      exit(1)
    end
    if File.exist?(File.join(absolutepathback, name))
      checkd_run('sudo','rm','-rf', File.join(absolutepathdir,'gogs'))
      checkd_run('sudo','rm','-rf',File.join(absolutepathdir,'drone'))
      checkd_run('sudo','rm','-rf',File.join(absolutepathdir,'mysql'))
      checkd_run('sudo','tar','-xvf',File.join(absolutepathback, name),'-C',File.join(absolutepathdir,'backup'))
      checkd_run('sudo','cp','-r',File.join(absolutepathdir,'backup','tmp','currentbackup','gogs'),File.join(absolutepathdir,'gogs'))
      checkd_run('sudo','cp','-r',File.join(absolutepathdir,'backup','tmp','currentbackup','drone'),File.join(absolutepathdir,'drone'))
      checkd_run('sudo','cp','-r',File.join(absolutepathdir,'backup','tmp','currentbackup','mysql'),File.join(absolutepathdir,'mysql'))
      checkd_run('sudo','mkdir','/tmp/currentbackup/')
      checkd_run('sudo','mv',File.join(absolutepathdir,'backup','tmp','currentbackup','kanboard_data.tar.bz2'),'/tmp/currentbackup/')
      checkd_run('sudo','mv',File.join(absolutepathdir,'backup','tmp','currentbackup','drone-server-data.tar.bz2'),'/tmp/currentbackup/')
      checkd_run('sudo','docker','run','--rm','-v','kanboard_data:/volume','-v','/tmp/currentbackup:/backup','alpine','sh','-c','"','rm','-rf','/volume/*','/volume/..?*','/volume/.[!.]*',';','tar', '-C', '/volume/', '-xjf', 'backup/kanboard_data.tar.bz2','"')
      checkd_run('sudo','docker','run','--rm','-v','drone-server-data:/volume','-v','/tmp/currentbackup:/backup','alpine','sh','-c','"','rm','-rf','/volume/*','/volume/..?*','/volume/.[!.]*',';','tar', '-C', '/volume/', '-xjf', 'backup/drone-server-data.tar.bz2','"')
      checkd_run('sudo','rm','-rf',File.join(absolutepathdir,'backup','tmp'))
      checkd_run('sudo','rm','-rf','/tmp/currentbackup/')
    else
      puts("Архива с введенным именем не существует, введите правильное имя")
      zip(pathdir,pathback,method)
    end
  end
end


if __FILE__ == $0
  options = {}
  OptionParser.new do |opt|
    opt.on('--pathdir PATHDIR') { |o| options[:pathd] = o }
    opt.on('--pathback PATHBACK') { |o| options[:pathb] = o }
    opt.on('--method METHOD') { |o| options[:method] = o }
  end.parse!
  if options.size != 3
    puts "pathdir - Путь до главной директории(в которой лежит папка backup)"
    puts "pathbackup - Путь до директории которая содержит(будет содержать) backup-архив"
    puts "method - zip(заархивировать)/unzip(распаковать)"
    puts "Нужно ввести три параметра (--pathdir=pathdir,--pathback=pathback,--method=zip/unzip)"
  exit(1)
  end
  puts options
  check_error(options[:pathd],options[:pathb],options[:method])
  zip(options[:pathd],options[:pathb],options[:method])
end