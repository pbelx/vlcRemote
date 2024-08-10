import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:text_marquee/text_marquee.dart';
// import 'package:marquee/marquee.dart';

class RemotePage extends StatefulWidget {
  const RemotePage({super.key});

  @override
  State<RemotePage> createState() => _RemotePageState();
}

class _RemotePageState extends State<RemotePage> {
  String serverIp = "192.168.1.12";
  String serverPort = "9090";
  String nowplaying = "Rowdy music";

  late TextEditingController _ipController;
  late TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: serverIp);
    _portController = TextEditingController(text: serverPort);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void updateServerAddress() {
    setState(() {
      serverIp = _ipController.text;
      serverPort = _portController.text;
    });
  }

  Future<void> sendVlcCommand(String message) async {
    try {
      // print("Sending command: $message");
      Dio dio = Dio();

      await dio.post('http://$serverIp:$serverPort/vlc/$message');
      Response response =
          await dio.post('http://$serverIp:$serverPort/vlc/get_title');
      setState(() {
        nowplaying = response.data['response'].toString();
      });

      // print(response);
    } catch (e) {
      // print("Error sending command: $e");
    }
  }

  Future<void> getSong() async {
    try {
      // print("Getting current song");
      Dio dio = Dio();
      Response response =
          await dio.post('http://$serverIp:$serverPort/vlc/get_title');
      setState(() {
        nowplaying = response.data.toString();
      });
      // print(response);
    } catch (e) {
      // print("Error getting song: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black87,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 10, 4),
                    child: const Text(
                      'BXMedia',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    )),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color.fromARGB(255, 186, 186, 25))),
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Icon(
                          Icons.library_music_rounded,
                          size: 32,
                          color: Color.fromARGB(255, 191, 35, 35),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                            child:
                                // Text(
                                //   nowplaying,
                                //   style: const TextStyle(color: Colors.white70),
                                //   overflow: TextOverflow.ellipsis,
                                // ),
                                TextMarquee(
                                  
                          nowplaying,
                          spaceSize: 72,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(Icons.play_arrow, 'play'),
                _buildControlButton(Icons.pause, 'pause'),
                _buildControlButton(Icons.fast_rewind, 'prev'),
                _buildControlButton(Icons.stop, 'stop'),
                _buildControlButton(Icons.fast_forward, 'next'),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color.fromARGB(255, 186, 186, 25))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text(
                    "Volume",
                    style: TextStyle(color: Colors.white70),
                  ),
                  _buildVolumeButton(Icons.arrow_back_ios, 'voldown'),
                  _buildVolumeButton(Icons.arrow_forward_ios, 'volup'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    style: const TextStyle(color: Colors.white70),
                    decoration: const InputDecoration(
                      labelText: 'IP Address',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 217, 217, 24)),
                      ),
                    ),
                    onChanged: (value) {
                      _ipController.value = _ipController.value.copyWith(
                        text: value,
                        selection:
                            TextSelection.collapsed(offset: value.length),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _portController,
                    style: const TextStyle(color: Colors.white70),
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 217, 217, 24)),
                      ),
                    ),
                    onChanged: (value) {
                      _portController.value = _portController.value.copyWith(
                        text: value,
                        selection:
                            TextSelection.collapsed(offset: value.length),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: updateServerAddress,
              child: const Text('Update Server'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String command) {
    return GestureDetector(
      onTap: () => sendVlcCommand(command),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color.fromARGB(255, 217, 217, 24)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[800],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Icon(
            icon,
            color: const Color.fromARGB(255, 217, 217, 24),
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeButton(IconData icon, String command) {
    return GestureDetector(
      onTap: () => sendVlcCommand(command),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[800],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(
            icon,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
