#!/usr/bin/env ruby
require 'optparse'

# Методы `checked_run` и `if __FILE__` были найдены в старых лабораторных

def checked_run(*args, dir: nil)
  command = args.join(' ')
  if !dir.nil?
    command = "cd #{dir} && #{command}"
  end
  puts "Комманда: #{command}"
  system(command)    
end

# Информацию про бэкап именованных volumes (В моем случае это `kanboard_data` и `drone-server-data`) нашел здесь 
# https://medium.com/@loomchild/backup-restore-docker-named-volumes-350397b8e362

def main(dir,backup,method)
  name = nil
  absolutedir = File.expand_path(dir)
  absolutebackup = File.expand_path(backup)
  
  if method == "zip"
    puts("Введите имя архива обязательно с расширением tar(пример: backup.tar)")
    name = gets.chomp

    if !File.exist?(File.join(absolutebackup, name))
      checked_run('sudo','rm','-rf','/tmp/currentbackup/')
      checked_run('sudo','mkdir','/tmp/currentbackup/')
      checked_run('sudo','docker','run', '--rm', '-v', 'kanboard_data:/volume', '-v', '/tmp/currentbackup:/backup', 'alpine', 'tar', '-cjf', 'backup/kanboard_data.tar.bz2', '-C', '/volume', './' )
      checked_run('sudo','docker','run', '--rm', '-v', 'drone-server-data:/volume', '-v', '/tmp/currentbackup:/backup', 'alpine', 'tar', '-cjf', 'backup/drone-server-data.tar.bz2', '-C', '/volume', './' )
      checked_run('sudo','cp','-r',File.join(absolutedir,'gogs'), '/tmp/currentbackup/gogs/')
      checked_run('sudo','cp','-r',File.join(absolutedir,'drone'),'/tmp/currentbackup/drone/') 
      checked_run('sudo','cp','-r',File.join(absolutedir,'mysql'),'/tmp/currentbackup/mysql/')      
      checked_run('sudo','tar','-cvf',File.join(absolutebackup,name),'/tmp/currentbackup/')
      checked_run('sudo','rm','-rf','/tmp/currentbackup')
    else
      puts "Такой архив уже есть, попробуйте снова"
      main(dir,backup,method)
    end

  elsif method == "unzip"
    puts("Введите имя архива обязательно с расширением tar для распаковки(пример: backup.tar)")
    name = gets.chomp

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
      puts("Архива не существует, попробуйте снова")
      main(dir,backup,method)
    end

  end
end

if __FILE__ == $0

  hash_option = {}
  OptionParser.new do |opts|
    opts.banner = "Используйте: ruby backup.rb --dir=[projectDirectory] --backup=[backupDirectory] --method=[zip/unzip]"
    opts.on('--dir [ProjectDir]') do |v| 
      hash_option[:dirpath] = v 
    end
    opts.on('--backup [BackupDir]') do |v|
      hash_option[:backuppath] = v
    end
    opts.on('--method [Method]') do |v| 
      hash_option[:method] = v 
    end
    opts.on('--help', '-h') do 
      puts opts
      exit
    end
  end.parse!

  if hash_option[:dirpath].nil? && hash_option[:backuppath].nil? && hash_option[method].nil? && hash_option.size < 3
    puts "Нужно три параметра (--dir=[projectDirectory], --backup=[backupDirectory], --method=[zip/unzip])"
    exit(1)
  end

  puts hash_option
  main(hash_option[:dirpath],hash_option[:backuppath],hash_option[:method])
end