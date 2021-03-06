require_relative '../src/tools'

# service(logline) -  возвращает имя сервиса, которому
#   принадлежит данная строка. Если строка не удовлетворяет шаблону,
#   то возвращается nil. Предполагается, что либо в регулярном выражении 
#   присутствует поле service, либо метод переопределен так, чтобы возвращать
#   имя определенного сервиса
# LogFormat.find(logline) - возвращает либо nil, если такой формат лога
#                           не найден, либо нужный подкласс

class LogFormat
  @format = nil
  @all_formats = nil
  @service_name

  def LogFormat.check(logline)
  	if logline =~ @format
  	  return true
  	else
  	  return false
  	end
  end

  def LogFormat.parse!(logline)
  	logline =~ @format
    if $~ == nil
      return nil
    else
      data = $~.to_h
      if data.has_key? "service"
        return data
      else
        return data.update({"service"=>service})
      end
    end
  end

  def LogFormat.service
  	return 'service'
  end

  def LogFormat.find(logline)
    @all_formats = ObjectSpace.each_object(Class).select {|klass| klass < self} if @all_formats == nil 
    i = @all_formats.index {|log_format| log_format.check(logline)}
    return i == nil ? nil : @all_formats[i]
  end
end

class SyslogFormat<LogFormat
  @format = %r{  ^
      (?<month>\S+)\s+    		# Oct
      (?<day>\d+)\s+      		# 9
      (?<hour>\d+):     		# 06:
      (?<minute>\d+):   		# 08:
      (?<second>\d+)\s+   		# 05
      (?<server>\S+)\s+         # newserv
      (?<service>[^\[:]+)    # systemd-logind - все, вплоть до квадратной скобки или :
      (\[(?<pid>\d+)\])?     # [10405] - может идти, а может и не идти за именем сервиса
      :\s+(?<msg>.*)            # : Accepted publickey for autocheck
  }x
end

class ApacheFormat<LogFormat
  @format = %r{  ^
  	# IP Address
  	(?<user_ip> \S+)    # 93.180.9.182
  	# Time
  	(\s-\s-\s\[)           #  - - [
   	(?<day> \d+)\/      # 09/
   	(?<month> \w+)\/    # Oct/
   	(?<year> \d+)\:     # 2016:
   	(?<hour> \d+)\:     # 06:
   	(?<minute> \d+)\:   # 35:
   	(?<second> \d+)\s   # 46
   	(?<timezone> \+\d+)\]\s 	# +0300] 
   	# Method
   	\" (?<method> \S+)\s   					# "GET
   	# Path
   	(?<path> [^\?\s]+)\S*\s    				# /robots.txt
   	# HTTP version
   	\w+\/(?<http_version> \d\.\d)\"\s   		# HTTP/1.0"
   	# Error code
   	(?<code> \d+)      
  }x
  def self.service
  	'apache'
  end
end

class Fail2BanFormat<LogFormat
  @format = %r{	 ^
  	# Time
    (?<year>\d+)-       # 2017-
    (?<month>\d+)-      # 02-
    (?<day>\d+)\s+      # 05
    (?<hour>\d+):       # 07:
    (?<minute>\d+):     # 05:
    (?<second>\d+),     # 13,
    (?<msecond>\d+)		# 390
    \s+
    # Service, type
    (?<service>[^\.]+)
    \.
    (?<type>\S+)
    \s+
    # PID
    \[(?<pid>\d+)\]:     # [1686]: 
    \s+
    # Warning level
    (?<level>\S+)        # INFO
    \s+
    # Service name
    (\[([\w\-]+)\])? # [pam-generic]
    \s+
    (?<msg>.*)             # rollover performed on /var/log/fail2ban.log
  }x
end