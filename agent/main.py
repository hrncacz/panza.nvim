

def main():
    while True:
        print("Your question?")
        test_input = input()
        print("YOUR INPUT " + test_input)
        if test_input.lower() == "exit":
            break
        if test_input.lower() == "test_error":
            # raise Exception("Testovaci chyba")
            return 3/0
    exit(0)
main()
